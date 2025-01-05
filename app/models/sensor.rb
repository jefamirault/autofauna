class Sensor < ApplicationRecord
  belongs_to :project
  belongs_to :zone
  belongs_to :sensor_type
  has_many :hygro_sensor_readings

  def readings
    self.hygro_sensor_readings
  end

  def to_s
    self.name
  end

  def last_temp
    hygro_sensor_readings.last&.temp
  end

  def last_humidity
    hygro_sensor_readings.last&.humidity
  end
end
