class Sensor < ApplicationRecord
  belongs_to :project
  belongs_to :zone
  has_many :hygro_sensor_readings

  def readings
    self.hygro_sensor_readings
  end

  def to_s
    self.name
  end
end
