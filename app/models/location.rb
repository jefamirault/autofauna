class Location < ApplicationRecord
  belongs_to :zone, optional: true
  has_many :plants

  def to_s
    self.name
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[name zone_id]
  end
end
