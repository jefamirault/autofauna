class SensorType < ApplicationRecord
  has_many :sensors

  def to_s
    self.name
  end
end
