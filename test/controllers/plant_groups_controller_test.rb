require "test_helper"

class PlantGroupsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @group = plant_groups(:one)
    sign_in @user
  end

  test "should get index" do
    get plant_groups_url
    assert_response :success
  end

  test "should get new" do
    get new_plant_group_url
    assert_response :success
  end

  test "should show group" do
    get plant_group_url(@group)
    assert_response :success
  end

  test "should get edit" do
    get edit_plant_group_url(@group)
    assert_response :success
  end

  test "should create group" do
    assert_difference("PlantGroup.count") do
      post plant_groups_url, params: { plant_group: { name: "Bedroom", color: "#0E487B" } }
    end
    assert_redirected_to plant_group_url(PlantGroup.last)
  end

  test "create assigns plants scoped to current project" do
    post plant_groups_url, params: { plant_group: { name: "Desk", plant_ids: [plants(:one).id] } }
    group = PlantGroup.last
    assert_includes group.plants, plants(:one)
  end

  test "should update group" do
    patch plant_group_url(@group), params: { plant_group: { name: "Updated" } }
    assert_redirected_to plant_group_url(@group)
    assert_equal "Updated", @group.reload.name
  end

  test "update with apply_schedule pushes schedule to members" do
    patch plant_group_url(@group),
      params: { plant_group: { min_watering_freq: 4, max_watering_freq: 6 }, apply_schedule: "1" }
    assert_equal 4, plants(:one).reload.min_watering_freq
    assert_equal 6, plants(:one).reload.max_watering_freq
  end

  test "should destroy group" do
    assert_difference("PlantGroup.count", -1) do
      delete plant_group_url(@group)
    end
    assert_redirected_to plant_groups_url
  end

  test "water creates one watering per member and redirects" do
    members = @group.plants.where(archived: false).count
    assert_difference("Watering.count", members) do
      post water_plant_group_url(@group)
    end
    assert_redirected_to plants_path
  end

  test "water responds with turbo stream" do
    post water_plant_group_url(@group), as: :turbo_stream
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
  end

  test "seed_from_location creates a group from the location's plants" do
    location = locations(:one)
    assert_difference("PlantGroup.count") do
      post seed_from_location_plant_groups_url, params: { location_id: location.id }
    end
    group = PlantGroup.last
    assert_equal location.name, group.name
    assert_equal location.plants.pluck(:id).sort, group.plants.pluck(:id).sort
    assert_redirected_to edit_plant_group_url(group)
  end
end
