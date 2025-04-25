class Zone < ApplicationRecord
  belongs_to :project
  has_many :locations, dependent: :destroy
  has_many :plants, through: :locations
  has_many :sensors
  has_many :hygro_sensor_readings, through: :sensors

  def to_s
    self.name
  end

  def last_temp
    hygro_sensor_readings.last&.temp
  end

  def last_humidity
    hygro_sensor_readings.last&.humidity
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[name]
  end
end
