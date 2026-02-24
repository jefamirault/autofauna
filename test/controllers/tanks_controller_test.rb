require "test_helper"

class TanksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @tank = tanks(:one)
    sign_in @user
  end

  test "should get index" do
    get tanks_url
    assert_response :success
  end

  test "should get new" do
    get new_tank_url
    assert_response :success
  end

  test "should create tank" do
    assert_difference("Tank.count") do
      post tanks_url, params: { tank: { description: "New tank", name: "New Tank", project_id: @tank.project_id, location_id: locations(:one).id } }
    end

    assert_redirected_to tank_url(Tank.last)
  end

  test "should show tank" do
    get tank_url(@tank)
    assert_response :success
  end

  test "should get edit" do
    get edit_tank_url(@tank)
    assert_response :success
  end

  test "should update tank" do
    patch tank_url(@tank), params: { tank: { description: @tank.description, name: @tank.name, location_id: locations(:one).id } }
    assert_redirected_to tank_url(@tank)
  end

  test "should destroy tank" do
    assert_difference("Tank.count", -1) do
      delete tank_url(@tank)
    end

    assert_redirected_to tanks_url
  end
end
