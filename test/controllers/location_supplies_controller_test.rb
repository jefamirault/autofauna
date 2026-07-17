require "test_helper"

class LocationSuppliesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @location = locations(:one)
    @source = recipe_sources(:ro_water)
    @batch = recipe_batches(:grow_batch)
    sign_in @user
  end

  def existing_supply(quantity: 3.0, units: "gal", supplyable: nil)
    @location.location_supplies.create!(
      supplyable: supplyable || @source, quantity_units: units, quantity: quantity
    )
  end

  # --- create / add ---

  test "stocks a new supply at the location" do
    assert_difference("LocationSupply.count", 1) do
      post location_location_supplies_url(@location),
           params: { supplyable: "RecipeSource:#{@source.id}", amount: 5, units: "gal" }
    end
    assert_redirected_to location_url(@location)
    supply = @location.location_supplies.find_by(supplyable: @source)
    assert_in_delta 5.0, supply.quantity, 0.0001
  end

  test "can stock a recipe batch as a supply" do
    assert_difference("LocationSupply.count", 1) do
      post location_location_supplies_url(@location),
           params: { supplyable: "RecipeBatch:#{@batch.id}", amount: 2, units: "gal" }
    end
    supply = @location.location_supplies.find_by(supplyable: @batch)
    assert_in_delta 2.0, supply.quantity, 0.0001
  end

  test "adding to an existing supply does not create a duplicate row" do
    supply = existing_supply(quantity: 2.0)
    assert_no_difference("LocationSupply.count") do
      post location_location_supplies_url(@location),
           params: { supplyable: "RecipeSource:#{@source.id}", amount: 3, units: "gal" }
    end
    assert_in_delta 5.0, supply.reload.quantity, 0.0001
  end

  # --- adjust: add / remove / deplete ---

  test "adjust add increases the stock" do
    supply = existing_supply(quantity: 2.0)
    patch adjust_location_location_supply_url(@location, supply),
          params: { adjust_action: "add", amount: 1, units: "gal" }
    assert_redirected_to location_url(@location)
    assert_in_delta 3.0, supply.reload.quantity, 0.0001
  end

  test "adjust remove decreases the stock" do
    supply = existing_supply(quantity: 5.0)
    patch adjust_location_location_supply_url(@location, supply),
          params: { adjust_action: "remove", amount: 2, units: "gal" }
    assert_in_delta 3.0, supply.reload.quantity, 0.0001
    assert supply.location_supply_adjustments.last.remove?
  end

  test "adjust deplete zeroes the stock" do
    supply = existing_supply(quantity: 5.0)
    patch adjust_location_location_supply_url(@location, supply),
          params: { adjust_action: "deplete" }
    assert_equal 0.0, supply.reload.quantity
    assert supply.location_supply_adjustments.last.deplete?
  end

  # --- destroy ---

  test "removes a supply from the location" do
    supply = existing_supply
    assert_difference("LocationSupply.count", -1) do
      delete location_location_supply_url(@location, supply)
    end
    assert_redirected_to location_url(@location)
  end

  # --- show page renders the supplies section ---

  test "location show renders current stock" do
    existing_supply(quantity: 4.0)
    get location_url(@location)
    assert_response :success
    assert_match "Supplies", response.body
    assert_match @source.name, response.body
  end

  # --- multi-tenant / cross-tenant denial ---

  test "cannot stock a supply on another project's location" do
    other = locations(:location_p2)
    assert_no_difference("LocationSupply.count") do
      post location_location_supplies_url(other),
           params: { supplyable: "RecipeSource:#{@source.id}", amount: 5, units: "gal" }
    end
    assert_redirected_to plants_path
  end

  test "cannot attach another project's source" do
    foreign = recipe_sources(:source_p2)
    assert_no_difference("LocationSupply.count") do
      post location_location_supplies_url(@location),
           params: { supplyable: "RecipeSource:#{foreign.id}", amount: 5, units: "gal" }
    end
    assert_redirected_to location_url(@location)
  end

  test "cannot attach another project's batch" do
    foreign = recipe_batches(:batch_p2)
    assert_no_difference("LocationSupply.count") do
      post location_location_supplies_url(@location),
           params: { supplyable: "RecipeBatch:#{foreign.id}", amount: 5, units: "gal" }
    end
    assert_redirected_to location_url(@location)
  end

  test "cannot adjust a supply belonging to another project's location" do
    other_location = locations(:location_p2)
    # A supply that lives on project two's location.
    foreign_supply = other_location.location_supplies.create!(
      supplyable: recipe_sources(:source_p2), quantity_units: "gal", quantity: 1.0
    )
    patch adjust_location_location_supply_url(other_location, foreign_supply),
          params: { adjust_action: "deplete" }
    assert_redirected_to plants_path
    assert_in_delta 1.0, foreign_supply.reload.quantity, 0.0001
  end

  # --- feature flag gate ---

  test "redirects when use_fertilizers is disabled" do
    @user.update!(use_fertilizers: false)
    post location_location_supplies_url(@location),
         params: { supplyable: "RecipeSource:#{@source.id}", amount: 5, units: "gal" }
    assert_redirected_to plants_path
  end
end
