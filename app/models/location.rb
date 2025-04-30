class Location < ApplicationRecord
  belongs_to :zone, optional: true
  has_many :plants
  has_many :tanks
  belongs_to :project
  validates_presence_of :name
  
  def to_s
    self.name
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[name zone_id]
  end
end
