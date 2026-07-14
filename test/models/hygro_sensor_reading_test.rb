require "test_helper"

class HygroSensorReadingTest < ActiveSupport::TestCase
  setup do
    @project = projects(:one)
    @sensor = sensors(:one)
  end

  test "create_from_json creates a reading for a sensor in the project" do
    json = {
      'sensor_id' => @sensor.id,
      'temperature' => 71,
      'humidity' => 40,
      'datetime' => '2025-06-01 12:00:00'
    }
    reading = nil
    assert_difference "HygroSensorReading.count", 1 do
      reading = HygroSensorReading.create_from_json(json, @project)
    end
    assert reading.persisted?
    assert_equal @sensor, reading.sensor
    assert_equal @project, reading.project
  end

  test "create_from_json ignores a supplied id and does not clobber an existing record" do
    existing = hygro_sensor_readings(:one)
    original_temperature = existing.temperature
    json = {
      'id' => existing.id,
      'sensor_id' => @sensor.id,
      'temperature' => 999,
      'humidity' => 1,
      'datetime' => '2025-06-01 12:00:00'
    }
    reading = nil
    assert_difference "HygroSensorReading.count", 1 do
      reading = HygroSensorReading.create_from_json(json, @project)
    end
    assert reading.persisted?
    assert_not_equal existing.id, reading.id
    assert_equal original_temperature, existing.reload.temperature
  end

  test "create_from_json rejects a sensor_id from another project" do
    json = {
      'sensor_id' => sensors(:sensor_p2).id,
      'temperature' => 71,
      'humidity' => 40,
      'datetime' => '2025-06-01 12:00:00'
    }
    reading = nil
    assert_no_difference "HygroSensorReading.count" do
      reading = HygroSensorReading.create_from_json(json, @project)
    end
    assert reading.new_record?
    assert_nil reading.sensor
  end

  test "reading with a cross-project sensor fails validation" do
    reading = HygroSensorReading.new(
      project: @project,
      sensor: sensors(:sensor_p2),
      temperature: 71,
      humidity: 40,
      datetime: Time.zone.now
    )
    assert_not reading.valid?
    assert reading.errors[:sensor].present?
  end
end
