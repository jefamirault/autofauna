class Location < ApplicationRecord
  belongs_to :zone, optional: true
  has_many :plants
  has_many :tanks
  belongs_to :project
  validates_presence_of :name
  validates :color, format: { with: /\A#[0-9A-F]{6}\z/i }, allow_blank: true

  def to_s
    self.name
  end

  def hex_color
    color.presence || '#0E487B'
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[name zone_id color]
  end
end
