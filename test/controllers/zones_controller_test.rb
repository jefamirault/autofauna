require "test_helper"

class ZonesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @zone = zones(:one)
  end

  test "should get index" do
    get zones_url
    assert_response :success
  end

  test "should get new" do
    get new_zone_url
    assert_response :success
  end

  test "should create zone" do
    assert_difference("Zone.count") do
      post zones_url, params: { zone: { description: @zone.description, name: @zone.name, project_id: @zone.project_id } }
    end

    assert_redirected_to zone_url(Zone.last)
  end

  test "should show zone" do
    get zone_url(@zone)
    assert_response :success
  end

  test "should get edit" do
    get edit_zone_url(@zone)
    assert_response :success
  end

  test "should update zone" do
    patch zone_url(@zone), params: { zone: { description: @zone.description, name: @zone.name, project_id: @zone.project_id } }
    assert_redirected_to zone_url(@zone)
  end

  test "should destroy zone" do
    assert_difference("Zone.count", -1) do
      delete zone_url(@zone)
    end

    assert_redirected_to zones_url
  end
end
