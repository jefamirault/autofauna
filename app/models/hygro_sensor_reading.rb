class HygroSensorReading < ApplicationRecord
  belongs_to :project
  belongs_to :sensor

  def to_s
    "Temp: #{temperature}, Humidity: #{humidity}, Time: #{datetime}"
  end

  def temp
    temperature
  end

  def self.create_from_json(json, project)
    r = HygroSensorReading.new do |r|
      r.id = json['id']
      r.sensor_id = json['sensor_id']
      r.temperature = json['temperature']
      r.humidity = json['humidity']
      r.datetime = json['datetime']
      r.project = project
    end
    r.save
    r
  end
end