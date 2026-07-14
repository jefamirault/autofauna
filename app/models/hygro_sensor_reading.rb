class HygroSensorReading < ApplicationRecord
  belongs_to :project
  belongs_to :sensor

  validate :sensor_matches_project

  def to_s
    "Temp: #{temperature}, Humidity: #{humidity}, Time: #{datetime}"
  end

  def temp
    temperature
  end

  # Import path: never trust `id` (rows always insert as new records) and only
  # attach sensors that belong to the importing project.
  def self.create_from_json(json, project)
    r = HygroSensorReading.new do |r|
      r.sensor = project.sensors.find_by(id: json['sensor_id'])
      r.temperature = json['temperature']
      r.humidity = json['humidity']
      r.datetime = json['datetime']
      r.project = project
    end
    r.save
    r
  end

  private

  def sensor_matches_project
    errors.add(:sensor, :invalid) if sensor && sensor.project_id != project_id
  end
end