require "test_helper"

class LocationSupplyTest < ActiveSupport::TestCase
  setup do
    @location = locations(:one)
    @source = recipe_sources(:ro_water)
    @user = users(:one)
  end

  def build_supply(units: "gal", quantity: 0.0)
    @location.location_supplies.create!(
      supplyable: @source, quantity_units: units, quantity: quantity
    )
  end

  test "add! increases quantity and records an add adjustment" do
    supply = build_supply
    assert_difference -> { supply.location_supply_adjustments.count }, 1 do
      supply.add!(5, "gal", user: @user)
    end
    assert_in_delta 5.0, supply.reload.quantity, 0.0001
    adj = supply.location_supply_adjustments.last
    assert adj.add?
    assert_in_delta 5.0, adj.amount, 0.0001
    assert_in_delta 5.0, adj.quantity_after, 0.0001
    assert_equal @user, adj.user
  end

  test "add! converts differing units into the supply's canonical units" do
    supply = build_supply(units: "gal")
    supply.add!(4, "qt") # 4 qt == 1 gal
    assert_in_delta 1.0, supply.reload.quantity, 0.0001
  end

  test "remove! decreases quantity and clamps at zero" do
    supply = build_supply(quantity: 3.0)
    supply.remove!(5, "gal")
    assert_equal 0.0, supply.reload.quantity
    assert supply.location_supply_adjustments.last.remove?
  end

  test "deplete! zeroes the quantity and records the prior amount" do
    supply = build_supply(quantity: 4.0)
    supply.deplete!(user: @user)
    assert_equal 0.0, supply.reload.quantity
    adj = supply.location_supply_adjustments.last
    assert adj.deplete?
    assert_in_delta 4.0, adj.amount, 0.0001
  end

  test "only one supply per location + supplyable" do
    build_supply
    dup = @location.location_supplies.build(supplyable: @source, quantity_units: "gal")
    assert_not dup.valid?
  end

  test "rejects an unknown supplyable type" do
    supply = LocationSupply.new(location: @location, supplyable_type: "Plant", supplyable_id: 1)
    assert_not supply.valid?
    assert supply.errors[:supplyable_type].any?
  end

  test "supports a recipe batch as the supplyable" do
    batch = recipe_batches(:grow_batch)
    supply = @location.location_supplies.create!(supplyable: batch, quantity_units: "gal")
    supply.add!(2, "gal")
    assert_in_delta 2.0, supply.reload.quantity, 0.0001
    # Independent pools: the batch's own remaining_volume is untouched.
    assert_in_delta 5.0, batch.reload.remaining_volume, 0.0001
  end
end
