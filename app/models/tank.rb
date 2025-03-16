class Tank < ApplicationRecord
  has_many :tds_readings
  belongs_to :zone

  def to_s
    self.name
  end
end
