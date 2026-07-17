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

  test "water_all waters every non-archived plant in the location" do
    members = @location.plants.where(archived: false).count
    assert members > 0
    assert_difference("Watering.count", members) do
      post water_all_location_url(@location)
    end
    assert_redirected_to plants_path
  end
end
