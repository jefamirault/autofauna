require "test_helper"

class WateringsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @watering = waterings(:one)
  end

  test "should get index" do
    get waterings_url
    assert_response :success
  end

  test "should get new" do
    get new_watering_url
    assert_response :success
  end

  test "should create watering" do
    assert_difference("Watering.count") do
      post waterings_url, params: { watering: { date: @watering.date, notes: @watering.notes, plant_id: @watering.plant_id } }
    end

    assert_redirected_to watering_url(Watering.last)
  end

  test "should show watering" do
    get watering_url(@watering)
    assert_response :success
  end

  test "should get edit" do
    get edit_watering_url(@watering)
    assert_response :success
  end

  test "should update watering" do
    patch watering_url(@watering), params: { watering: { date: @watering.date, notes: @watering.notes, plant_id: @watering.plant_id } }
    assert_redirected_to watering_url(@watering)
  end

  test "should destroy watering" do
    assert_difference("Watering.count", -1) do
      delete watering_url(@watering)
    end

    assert_redirected_to waterings_url
  end
end
