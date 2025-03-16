require "test_helper"

class TdsReadingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tds_reading = tds_readings(:one)
  end

  test "should get index" do
    get tds_readings_url
    assert_response :success
  end

  test "should get new" do
    get new_tds_reading_url
    assert_response :success
  end

  test "should create tds_reading" do
    assert_difference("TdsReading.count") do
      post tds_readings_url, params: { tds_reading: { datetime: @tds_reading.datetime, sensor_id: @tds_reading.sensor_id, tds: @tds_reading.tds, zone_id: @tds_reading.zone_id } }
    end

    assert_redirected_to tds_reading_url(TdsReading.last)
  end

  test "should show tds_reading" do
    get tds_reading_url(@tds_reading)
    assert_response :success
  end

  test "should get edit" do
    get edit_tds_reading_url(@tds_reading)
    assert_response :success
  end

  test "should update tds_reading" do
    patch tds_reading_url(@tds_reading), params: { tds_reading: { datetime: @tds_reading.datetime, sensor_id: @tds_reading.sensor_id, tds: @tds_reading.tds, zone_id: @tds_reading.zone_id } }
    assert_redirected_to tds_reading_url(@tds_reading)
  end

  test "should destroy tds_reading" do
    assert_difference("TdsReading.count", -1) do
      delete tds_reading_url(@tds_reading)
    end

    assert_redirected_to tds_readings_url
  end
end
