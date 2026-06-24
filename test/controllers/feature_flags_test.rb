require "test_helper"

class FeatureFlagsTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user
  end

  test "fertilizer pages redirect when use_fertilizers disabled" do
    @user.update!(use_fertilizers: false)

    get recipes_url
    assert_redirected_to plants_path

    get recipe_sources_url
    assert_redirected_to plants_path

    get recipe_batches_url
    assert_redirected_to plants_path
  end

  test "fertilizer pages accessible when use_fertilizers enabled" do
    get recipes_url
    assert_response :success
  end

  test "tank pages redirect when has_aquarium disabled" do
    @user.update!(has_aquarium: false)

    get tanks_url
    assert_redirected_to plants_path
  end

  test "watering history redirects but logging form stays reachable when track_waterings disabled" do
    @user.update!(track_waterings: false)

    # History index is gated...
    get waterings_url
    assert_redirected_to plants_path

    # ...but the detailed logging form is reachable so it can be used (first-use enable).
    get new_watering_url(plant_id: plants(:one).id)
    assert_response :success
  end

  test "logging a detailed watering enables track_waterings" do
    @user.update!(track_waterings: false)

    post waterings_url, params: { watering: { watered_at: Time.zone.now, notes: "Detailed", plant_id: plants(:one).id } }
    assert @user.reload.track_waterings?
  end

  test "recording a volume enables precise_measurements" do
    @user.update!(precise_measurements: false)

    post waterings_url, params: { watering: { watered_at: Time.zone.now, volume: 2.0, plant_id: plants(:one).id } }
    assert @user.reload.precise_measurements?
  end

  test "watering create still works when track_waterings disabled" do
    @user.update!(track_waterings: false)

    assert_difference("Watering.count") do
      post waterings_url, params: { watering: { watered_at: Time.zone.now, notes: "Quick water", plant_id: plants(:one).id } }
    end
    assert_redirected_to plant_url(plants(:one))
  end

  test "quick water still works when track_waterings disabled" do
    @user.update!(track_waterings: false)

    assert_difference("Watering.count") do
      post plant_quick_water_path(plants(:one))
    end
    assert_redirected_to plants_path
  end

  test "soil moisture index redirects but logging form stays reachable when track_soil_moisture disabled" do
    @user.update!(track_soil_moisture: false)

    get plant_soil_moisture_readings_url(plants(:one))
    assert_redirected_to plants_path

    get new_plant_soil_moisture_reading_url(plants(:one))
    assert_response :success
  end

  test "logging a soil moisture reading enables track_soil_moisture" do
    @user.update!(track_soil_moisture: false)

    post plant_soil_moisture_readings_url(plants(:one)),
      params: { soil_moisture_reading: { measured_at: Time.zone.now, value_numeric: 45.0 } }
    assert @user.reload.track_soil_moisture?
  end

  test "plants index hides recipe display when use_fertilizers disabled" do
    recipe = Recipe.create!(name: "Test Mix", project: projects(:one))
    plants(:one).update_columns(recipe_id: recipe.id)

    get plants_url
    assert_includes response.body, "plant-card-recipe"

    @user.update!(use_fertilizers: false)
    get plants_url
    assert_not_includes response.body, "plant-card-recipe"
  end

  test "settings update persists feature flags" do
    patch settings_url, params: { user: { use_fertilizers: "0", has_aquarium: "0" } }
    assert_redirected_to settings_path

    @user.reload
    assert_not @user.use_fertilizers?
    assert_not @user.has_aquarium?
  end
end
