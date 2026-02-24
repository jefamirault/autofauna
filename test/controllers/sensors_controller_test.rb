require "test_helper"

class SensorsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @sensor = sensors(:one)
    sign_in @user
  end

  test "should get index" do
    get sensors_url
    assert_response :success
  end

  test "should get new" do
    get new_sensor_url
    assert_response :success
  end

  test "should create sensor" do
    assert_difference("Sensor.count") do
      post sensors_url, params: { sensor: { description: "New sensor", location: "Balcony", name: "Balcony Sensor", project_id: @sensor.project_id, zone_id: @sensor.zone_id, sensor_type_id: @sensor.sensor_type_id } }
    end

    assert_redirected_to sensor_url(Sensor.last)
  end

  test "should show sensor" do
    get sensor_url(@sensor)
    assert_response :success
  end

  test "should get edit" do
    get edit_sensor_url(@sensor)
    assert_response :success
  end

  test "should update sensor" do
    patch sensor_url(@sensor), params: { sensor: { description: @sensor.description, location: @sensor.location, name: @sensor.name, project_id: @sensor.project_id, zone_id: @sensor.zone_id, sensor_type_id: @sensor.sensor_type_id } }
    assert_redirected_to sensor_url(@sensor)
  end

  test "should destroy sensor" do
    assert_difference("Sensor.count", -1) do
      delete sensor_url(@sensor)
    end

    assert_redirected_to sensors_url
  end
end
