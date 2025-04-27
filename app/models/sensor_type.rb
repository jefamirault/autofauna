class SensorType < ApplicationRecord
  has_many :sensors
  belongs_to :project

  def to_s
    self.name
  end
end
