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
