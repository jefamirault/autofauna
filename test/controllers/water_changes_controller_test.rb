require "test_helper"

class WaterChangesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @tank = tanks(:one)
    @water_change = water_changes(:one)
    sign_in @user
  end

  test "should get index" do
    get tank_water_changes_url(@tank)
    assert_response :success
  end

  test "should get new" do
    get new_tank_water_change_url(@tank)
    assert_response :success
  end

  test "should create water change" do
    assert_difference("WaterChange.count") do
      post tank_water_changes_url(@tank), params: {
        water_change: { changed_at: Time.current, percentage: 25.0, notes: "Test change" }
      }
    end
    assert_redirected_to tank_url(@tank)
  end

  test "should get edit" do
    get edit_tank_water_change_url(@tank, @water_change)
    assert_response :success
  end

  test "should update water change" do
    patch tank_water_change_url(@tank, @water_change), params: {
      water_change: { percentage: 30.0 }
    }
    assert_redirected_to tank_url(@tank)
  end

  test "should destroy water change" do
    assert_difference("WaterChange.count", -1) do
      delete tank_water_change_url(@tank, @water_change)
    end
    assert_redirected_to tank_url(@tank)
  end

  test "should not access water change from another project" do
    sign_in users(:two)
    get new_tank_water_change_url(@tank)
    assert_redirected_to plants_url
  end
end
