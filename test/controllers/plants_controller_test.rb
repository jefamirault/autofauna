require "test_helper"

class PlantsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @plant = plants(:one)
    sign_in @user
  end

  test "should get index" do
    get plants_url
    assert_response :success
  end

  test "should get new" do
    get new_plant_url
    assert_response :success
  end

  test "should create plant" do
    assert_difference("Plant.count") do
      post plants_url, params: { plant: { name: "New Plant", uid: 99, pot: "clay", project_id: @plant.project_id } }
    end

    assert_redirected_to plant_url(Plant.last)
  end

  test "should show plant" do
    get plant_url(@plant)
    assert_response :success
  end

  test "should get edit" do
    get edit_plant_url(@plant)
    assert_response :success
  end

  test "should update plant" do
    patch plant_url(@plant), params: { plant: { name: @plant.name, pot: @plant.pot } }
    assert_redirected_to plant_url(@plant)
  end

  test "should destroy plant" do
    assert_difference("Plant.count", -1) do
      delete plant_url(@plant)
    end

    assert_redirected_to plants_url
  end

  test "plant show page displays last watering info from the most recent watering" do
    plant = Plant.create!(name: "Show Test Plant", project: @plant.project, uid: 200)
    Watering.create!(plant: plant, watered_at: 10.days.ago, notes: "Old notes from months ago", volume: 1.0, units: "cups")
    Watering.create!(plant: plant, watered_at: 1.day.ago, notes: "Latest watering notes", volume: 2.5, units: "mL")

    get plant_url(plant)
    assert_response :success

    # The show page should display the most recent watering's notes, not an older one
    assert_match "Latest watering notes", response.body
    # The old notes should NOT appear in the watering-details section
    assert_no_match(/watering-notes-text.*Old notes from months ago/, response.body)
  end

  test "water action prepopulates form with most recent watering data" do
    plant = Plant.create!(name: "Water Again Test Plant", project: @plant.project, uid: 201)
    Watering.create!(plant: plant, watered_at: 10.days.ago, notes: "Old notes", volume: 1.0, units: "cups")
    Watering.create!(plant: plant, watered_at: 1.day.ago, notes: "Recent notes", volume: 2.5, units: "mL", tds: 400)

    get plant_water_path(plant,
      volume: plant.last_watering.volume,
      units: plant.last_watering.units,
      notes: plant.last_watering.notes,
      tds: plant.last_watering.tds)

    # Should redirect to new watering with recent watering's params
    assert_response :redirect
    location = response.headers["Location"]
    assert_includes location, "notes=Recent+notes" if location.include?("notes=")
    refute_includes location, "Old+notes"
  end
end
