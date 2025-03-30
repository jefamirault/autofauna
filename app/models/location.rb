class Location < ApplicationRecord
  belongs_to :zone, optional: true
  has_many :plants

  def to_s
    self.name
  end
end
