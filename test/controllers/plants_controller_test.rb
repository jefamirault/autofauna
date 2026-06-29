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

  test "should attach a custom image on update" do
    image = fixture_file_upload("plant.png", "image/png")
    patch plant_url(@plant), params: { plant: { name: @plant.name, custom_image: image } }
    assert_redirected_to plant_url(@plant)
    assert @plant.reload.custom_image.attached?
  end

  test "should remove a custom image when the remove flag is set" do
    @plant.custom_image.attach(io: File.open(Rails.root.join("test/fixtures/files/plant.png")), filename: "plant.png", content_type: "image/png")
    assert @plant.custom_image.attached?

    patch plant_url(@plant), params: { plant: { name: @plant.name, remove_custom_image: "1" } }
    assert_redirected_to plant_url(@plant)
    assert_not @plant.reload.custom_image.attached?
  end

  test "uploaded image is not removed when the remove flag is set but a replacement is provided" do
    image = fixture_file_upload("plant.png", "image/png")
    patch plant_url(@plant), params: { plant: { name: @plant.name, remove_custom_image: "1", custom_image: image } }
    assert_redirected_to plant_url(@plant)
    assert @plant.reload.custom_image.attached?
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

  test "quick_water creates watering and returns turbo stream" do
    plant = Plant.create!(name: "Quick Water Test", project: @plant.project, uid: 300)

    assert_difference("Watering.count") do
      post plant_quick_water_path(plant), headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end

    assert_response :success
    assert_includes response.body, "turbo-stream"
  end

  test "quick_water carries forward last watering details" do
    plant = Plant.create!(name: "Carry Forward Test", project: @plant.project, uid: 301)
    Watering.create!(plant: plant, watered_at: 3.days.ago, volume: 2.5, units: "mL", notes: "test notes", tds: 400)

    assert_difference("Watering.count") do
      post plant_quick_water_path(plant), headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end

    new_watering = plant.waterings.reorder(watered_at: :desc).first
    assert_equal 2.5, new_watering.volume
    assert_equal "mL", new_watering.units
    assert_equal "test notes", new_watering.notes
    assert_equal 400, new_watering.tds
  end

  test "quick_water works with no watering history" do
    plant = Plant.create!(name: "No History Test", project: @plant.project, uid: 302)

    assert_difference("Watering.count") do
      post plant_quick_water_path(plant), headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end

    new_watering = plant.waterings.last
    assert_not_nil new_watering.watered_at
    assert_nil new_watering.volume
  end

  test "quick_water HTML fallback redirects to plants index" do
    plant = Plant.create!(name: "Fallback Test", project: @plant.project, uid: 303)

    post plant_quick_water_path(plant)

    assert_redirected_to plants_path
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

  # --- Bulk actions ---

  test "bulk_water waters every selected plant and returns turbo stream" do
    a = Plant.create!(name: "Bulk A", project: @plant.project, uid: 401)
    b = Plant.create!(name: "Bulk B", project: @plant.project, uid: 402)

    assert_difference("Watering.count", 2) do
      post bulk_water_plants_path, params: { plant_ids: [a.id, b.id] },
        headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
  end

  test "bulk_water applies override details to all selected plants" do
    a = Plant.create!(name: "Bulk Override A", project: @plant.project, uid: 403)
    b = Plant.create!(name: "Bulk Override B", project: @plant.project, uid: 404)

    post bulk_water_plants_path,
      params: { plant_ids: [a.id, b.id], watering: { volume: "3.5", units: "mL", notes: "Bulk feed" } },
      headers: { "Accept" => "text/vnd.turbo-stream.html" }

    [a, b].each do |plant|
      w = plant.waterings.last
      assert_equal 3.5, w.volume
      assert_equal "mL", w.units
      assert_equal "Bulk feed", w.notes
    end
  end

  test "bulk_water blank overrides fall back to carry-forward" do
    plant = Plant.create!(name: "Bulk Carry", project: @plant.project, uid: 405)
    Watering.create!(plant: plant, watered_at: 2.days.ago, notes: "previous", volume: 1.0, units: "cups")

    post bulk_water_plants_path,
      params: { plant_ids: [plant.id], watering: { volume: "", units: "", notes: "" } },
      headers: { "Accept" => "text/vnd.turbo-stream.html" }

    w = plant.waterings.reorder(watered_at: :desc).first
    assert_equal "previous", w.notes
    assert_equal 1.0, w.volume
  end

  test "bulk_water ignores recipe_id from another project" do
    plant = Plant.create!(name: "Bulk IDOR Recipe", project: @plant.project, uid: 406)
    foreign_recipe = Recipe.create!(name: "Foreign", project: projects(:two))

    post bulk_water_plants_path,
      params: { plant_ids: [plant.id], watering: { recipe_id: foreign_recipe.id } },
      headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_nil plant.waterings.last.recipe_id
  end

  test "bulk_archive archives selected plants and redirects" do
    a = Plant.create!(name: "Arch A", project: @plant.project, uid: 407)
    b = Plant.create!(name: "Arch B", project: @plant.project, uid: 408)

    post bulk_archive_plants_path, params: { plant_ids: [a.id, b.id] }
    assert_redirected_to plants_path
    assert a.reload.archived
    assert b.reload.archived
  end

  test "bulk_set_location moves selected plants" do
    plant = Plant.create!(name: "Move Me", project: @plant.project, uid: 409)
    location = locations(:two)

    post bulk_set_location_plants_path, params: { plant_ids: [plant.id], location_id: location.id }
    assert_redirected_to(/#{Regexp.escape(plants_path)}/)
    assert_equal location.id, plant.reload.location_id
  end

  test "bulk actions cannot touch another project's plants" do
    foreign = plants(:plant_p2)

    post bulk_archive_plants_path, params: { plant_ids: [foreign.id] }
    refute foreign.reload.archived
  end

  test "bulk_water with empty selection creates no waterings" do
    assert_no_difference("Watering.count") do
      post bulk_water_plants_path, params: { plant_ids: [] },
        headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end
  end
end
