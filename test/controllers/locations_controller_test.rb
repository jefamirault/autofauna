require "test_helper"

class LocationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @location = locations(:one)
    sign_in @user
  end

  test "should get index" do
    get locations_url
    assert_response :success
  end

  test "should get new" do
    get new_location_url
    assert_response :success
  end

  test "should create location" do
    assert_difference("Location.count") do
      post locations_url, params: { location: { description: "New location", name: "Kitchen", project_id: @location.project_id } }
    end

    assert_redirected_to location_url(Location.last)
  end

  test "should show location" do
    get location_url(@location)
    assert_response :success
  end

  test "should get edit" do
    get edit_location_url(@location)
    assert_response :success
  end

  test "should update location" do
    patch location_url(@location), params: { location: { description: @location.description, name: @location.name, project_id: @location.project_id } }
    assert_redirected_to location_url(@location)
  end

  test "should create location with picture" do
    image = fixture_file_upload("plant.png", "image/png")
    assert_difference("Location.count") do
      post locations_url, params: { location: { name: "Location with photo", project_id: @location.project_id, picture: image } }
    end

    assert_redirected_to location_url(Location.last)
    assert Location.last.picture.attached?
  end

  test "should attach a picture on update" do
    image = fixture_file_upload("plant.png", "image/png")
    patch location_url(@location), params: { location: { name: @location.name, picture: image } }
    assert_redirected_to location_url(@location)
    assert @location.reload.picture.attached?
  end

  test "should remove picture when the remove flag is set" do
    @location.picture.attach(io: File.open(Rails.root.join("test/fixtures/files/plant.png")), filename: "plant.png", content_type: "image/png")
    assert @location.picture.attached?

    patch location_url(@location), params: { location: { name: @location.name, remove_picture: "1" } }
    assert_redirected_to location_url(@location)
    assert_not @location.reload.picture.attached?
  end

  test "picture is not removed when the remove flag is set but a replacement is provided" do
    @location.picture.attach(io: File.open(Rails.root.join("test/fixtures/files/plant.png")), filename: "plant.png", content_type: "image/png")
    image = fixture_file_upload("plant.png", "image/png")
    patch location_url(@location), params: { location: { name: @location.name, remove_picture: "1", picture: image } }
    assert_redirected_to location_url(@location)
    assert @location.reload.picture.attached?
  end

  test "should reject a picture with an unsupported content type" do
    file = fixture_file_upload("not_an_image.txt", "text/plain")
    patch location_url(@location), params: { location: { name: @location.name, picture: file } }
    assert_response :unprocessable_entity
    assert_not @location.reload.picture.attached?
  end

  test "index and show render location picture" do
    @location.picture.attach(io: File.open(Rails.root.join("test/fixtures/files/plant.png")), filename: "plant.png", content_type: "image/png")

    get locations_url
    assert_response :success
    assert_match "resource-card-photo", response.body

    get location_url(@location)
    assert_response :success
    assert_match "location-photo-image", response.body
  end

  test "cannot attach a picture to another project's location" do
    other = locations(:location_p2)
    image = fixture_file_upload("plant.png", "image/png")
    patch location_url(other), params: { location: { name: other.name, picture: image } }
    assert_redirected_to plants_path
    assert_not other.reload.picture.attached?
  end

  test "should destroy location" do
    # Move plants to a different location first to avoid FK constraint
    @location.plants.update_all(location_id: nil)
    assert_difference("Location.count", -1) do
      delete location_url(@location)
    end

    assert_redirected_to locations_url
  end

  # ---- diagram / layout ---------------------------------------------------

  test "show renders a diagram chip per plant and a legend for their groups" do
    get location_url(@location)
    assert_response :success
    assert_select "#location-diagram"
    assert_select ".diagram-chip", @location.plants.where(archived: false).count
    assert_select ".legend-chip", text: /#{plant_groups(:one).name}/
  end

  test "show excludes archived plants from the diagram" do
    @location.plants.first.update!(archived: true)

    get location_url(@location)
    assert_response :success
    assert_select ".diagram-chip", @location.plants.where(archived: false).count
  end

  test "update_layout stores normalized coordinates" do
    plant = @location.plants.first

    patch layout_location_url(@location),
          params: { positions: [{ id: plant.id, x: 0.25, y: 0.75 }] }, as: :json

    assert_response :success
    plant.reload
    assert_in_delta 0.25, plant.layout_x, 0.0001
    assert_in_delta 0.75, plant.layout_y, 0.0001
  end

  test "update_layout clamps coordinates to the canvas" do
    plant = @location.plants.first

    patch layout_location_url(@location),
          params: { positions: [{ id: plant.id, x: 1.8, y: -0.4 }] }, as: :json

    assert_response :success
    plant.reload
    assert_in_delta 1.0, plant.layout_x, 0.0001
    assert_in_delta 0.0, plant.layout_y, 0.0001
  end

  test "update_layout unplaces a plant when coordinates are null" do
    plant = @location.plants.first
    plant.update!(layout_x: 0.3, layout_y: 0.3)

    patch layout_location_url(@location),
          params: { positions: [{ id: plant.id, x: nil, y: nil }] }, as: :json

    assert_response :success
    plant.reload
    assert_nil plant.layout_x
    assert_nil plant.layout_y
  end

  test "update_layout ignores a plant belonging to another project" do
    other = plants(:plant_p2)

    patch layout_location_url(@location),
          params: { positions: [{ id: other.id, x: 0.5, y: 0.5 }] }, as: :json

    assert_response :success
    assert_nil other.reload.layout_x
  end

  test "update_layout ignores a plant that lives in a different location" do
    plant = @location.plants.first
    elsewhere = locations(:two)

    patch layout_location_url(elsewhere),
          params: { positions: [{ id: plant.id, x: 0.5, y: 0.5 }] }, as: :json

    assert_response :success
    assert_nil plant.reload.layout_x
  end

  test "cannot save a layout on another project's location" do
    other = locations(:location_p2)

    patch layout_location_url(other),
          params: { positions: [{ id: plants(:plant_p2).id, x: 0.5, y: 0.5 }] }, as: :json

    assert_redirected_to plants_path
    assert_nil plants(:plant_p2).reload.layout_x
  end

  test "viewers can see the diagram but cannot save positions" do
    plant = @location.plants.first
    sign_in viewer_of_project_one

    get location_url(@location)
    assert_response :success
    assert_select "#location-diagram"

    patch layout_location_url(@location),
          params: { positions: [{ id: plant.id, x: 0.5, y: 0.5 }] }, as: :json

    assert_response :redirect
    assert_nil plant.reload.layout_x
  end

  test "index shows a mini-diagram only for locations with a layout" do
    get locations_url
    assert_response :success
    assert_select ".resource-card-diagram", 0

    @location.plants.first.update!(layout_x: 0.2, layout_y: 0.4)

    get locations_url
    assert_response :success
    assert_select ".resource-card-diagram", 1
  end

  test "water_all waters every non-archived plant in the location" do
    members = @location.plants.where(archived: false).count
    assert members > 0
    assert_difference("Watering.count", members) do
      post water_all_location_url(@location)
    end
    assert_redirected_to plants_path
  end

  private

    # A collaborator with view-only access to project one. Their own default project is
    # removed so `auto_select_project` lands them on the shared project.
    def viewer_of_project_one
      viewer = User.create!(email: "viewer@example.com", password: "password",
                            onboarding_completed_at: Time.current)
      viewer.projects.destroy_all
      Collaboration.create!(user: viewer, project: projects(:one), role: :viewer)
      viewer
    end
end
