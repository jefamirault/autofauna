require "test_helper"

class SensorTypesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @sensor_type = sensor_types(:one)
    sign_in @user
  end

  test "should get index" do
    get sensor_types_url
    assert_response :success
  end

  test "should get new" do
    get new_sensor_type_url
    assert_response :success
  end

  test "should create sensor_type" do
    assert_difference("SensorType.count") do
      post sensor_types_url, params: { sensor_type: { accuracy_humidity: 1.5, accuracy_temp: 0.5, max_humidity: 100, max_temp: 80, min_humidity: 0, min_temp: -40, name: "New Sensor Type", resolution_humidity: 0.1, resolution_temp: 0.1, project_id: @sensor_type.project_id } }
    end

    assert_redirected_to sensor_type_url(SensorType.last)
  end

  test "should show sensor_type" do
    get sensor_type_url(@sensor_type)
    assert_response :success
  end

  test "should get edit" do
    get edit_sensor_type_url(@sensor_type)
    assert_response :success
  end

  test "should update sensor_type" do
    patch sensor_type_url(@sensor_type), params: { sensor_type: { accuracy_humidity: @sensor_type.accuracy_humidity, accuracy_temp: @sensor_type.accuracy_temp, max_humidity: @sensor_type.max_humidity, max_temp: @sensor_type.max_temp, min_humidity: @sensor_type.min_humidity, min_temp: @sensor_type.min_temp, name: @sensor_type.name, resolution_humidity: @sensor_type.resolution_humidity, resolution_temp: @sensor_type.resolution_temp } }
    assert_redirected_to sensor_type_url(@sensor_type)
  end

  test "should destroy sensor_type" do
    # Use sensor_type :two to avoid FK issues with sensors referencing :one
    sensor_type = sensor_types(:two)
    assert_difference("SensorType.count", -1) do
      delete sensor_type_url(sensor_type)
    end

    assert_redirected_to sensor_types_url
  end
end
