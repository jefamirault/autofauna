require "test_helper"

class TransmitControllerTest < ActionDispatch::IntegrationTest
  setup do
    @project = projects(:one)
    @project.update!(api_key: "test-api-key-12345")
    @sensor = sensors(:one)
  end

  test "valid request creates a hygro sensor reading" do
    assert_difference "HygroSensorReading.count", 1 do
      get transmit_url, params: {
        project_id: @project.id,
        API_KEY: "test-api-key-12345",
        sensor_id: @sensor.id,
        temp: 72,
        humidity: 45
      }
    end
    assert_response :success
  end

  test "valid request with optional error param stores error on reading" do
    assert_difference "HygroSensorReading.count", 1 do
      get transmit_url, params: {
        project_id: @project.id,
        API_KEY: "test-api-key-12345",
        sensor_id: @sensor.id,
        temp: 72,
        humidity: 45,
        error: "Sensor timeout"
      }
    end
    assert_response :success
    reading = HygroSensorReading.order(:created_at).last
    assert_equal "Sensor timeout", reading.error
  end

  test "wrong API key is rejected without creating reading" do
    assert_no_difference "HygroSensorReading.count" do
      get transmit_url, params: {
        project_id: @project.id,
        API_KEY: "wrong-key",
        sensor_id: @sensor.id,
        temp: 72,
        humidity: 45
      }
    end
    assert_response :success
    assert_match /Hello Arduino/, response.body
  end

  test "missing required params returns error response" do
    assert_no_difference "HygroSensorReading.count" do
      get transmit_url, params: {
        project_id: @project.id,
        API_KEY: "test-api-key-12345"
        # missing temp and humidity
      }
    end
    assert_response :success
    assert_match /Unauthorized/, response.body
  end

  test "missing project_id returns Unauthorized response" do
    assert_no_difference "HygroSensorReading.count" do
      get transmit_url, params: {
        API_KEY: "test-api-key-12345",
        sensor_id: @sensor.id,
        temp: 72,
        humidity: 45
      }
    end
    # project_id is a required param; the endpoint answers for itself rather than
    # relying on a session/redirect (transmit is public, unauthenticated).
    assert_response :success
    assert_match /Unauthorized/, response.body
  end

  test "sensor from another project is not attached to the reading" do
    # Correct API key for project one, but a sensor_id belonging to project two.
    assert_no_difference "HygroSensorReading.count" do
      get transmit_url, params: {
        project_id: @project.id,
        API_KEY: "test-api-key-12345",
        sensor_id: sensors(:sensor_p2).id,
        temp: 72,
        humidity: 45
      }
    end
    assert_response :success
  end

  test "project with nil api_key rejects request" do
    @project.update!(api_key: nil)
    assert_no_difference "HygroSensorReading.count" do
      get transmit_url, params: {
        project_id: @project.id,
        API_KEY: "any-key",
        sensor_id: @sensor.id,
        temp: 72,
        humidity: 45
      }
    end
    assert_response :success
    assert_match /Hello Arduino/, response.body
  end

  test "API key via Authorization Bearer header creates a reading (no key in URL)" do
    assert_difference "HygroSensorReading.count", 1 do
      get transmit_url,
        params: { project_id: @project.id, sensor_id: @sensor.id, temp: 72, humidity: 45 },
        headers: { "Authorization" => "Bearer test-api-key-12345" }
    end
    assert_response :success
    assert_match /Hello Programmer/, response.body
  end

  test "API key via X-Api-Key header creates a reading" do
    assert_difference "HygroSensorReading.count", 1 do
      get transmit_url,
        params: { project_id: @project.id, sensor_id: @sensor.id, temp: 72, humidity: 45 },
        headers: { "X-Api-Key" => "test-api-key-12345" }
    end
    assert_response :success
  end

  test "wrong API key in header is rejected" do
    assert_no_difference "HygroSensorReading.count" do
      get transmit_url,
        params: { project_id: @project.id, sensor_id: @sensor.id, temp: 72, humidity: 45 },
        headers: { "Authorization" => "Bearer wrong-key" }
    end
    assert_response :success
    assert_match /Hello Arduino/, response.body
  end

  test "missing API key entirely returns Unauthorized" do
    assert_no_difference "HygroSensorReading.count" do
      get transmit_url, params: {
        project_id: @project.id, sensor_id: @sensor.id, temp: 72, humidity: 45
      }
    end
    assert_response :success
    assert_match /Unauthorized/, response.body
  end

  test "reading attributes are HTML-escaped in the response" do
    get transmit_url, params: {
      project_id: @project.id,
      API_KEY: "test-api-key-12345",
      sensor_id: @sensor.id,
      temp: "<script>alert(1)</script>",
      humidity: 45
    }
    assert_response :success
    assert_no_match /<script>alert/, response.body
  end

  test "valid request stores correct temperature and humidity" do
    get transmit_url, params: {
      project_id: @project.id,
      API_KEY: "test-api-key-12345",
      sensor_id: @sensor.id,
      temp: 68,
      humidity: 55
    }
    assert_response :success
    reading = HygroSensorReading.order(:created_at).last
    assert_equal 68, reading.temperature.to_i
    assert_equal 55, reading.humidity.to_i
    assert_equal @project, reading.project
    assert_equal @sensor, reading.sensor
  end
end
