class HygroSensorReading < ApplicationRecord
  belongs_to :project
  belongs_to :sensor

  def to_s
    "Temp: #{temperature}, Humidity: #{humidity}, Time: #{datetime}"
  end

  def temp
    temperature
  end
end