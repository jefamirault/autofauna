class Location < ApplicationRecord
  include HasPicture

  belongs_to :zone, optional: true
  has_many :plants
  has_many :tanks
  has_many :location_supplies, dependent: :destroy
  belongs_to :project
  validates_presence_of :name
  validates :color, format: { with: /\A#[0-9A-F]{6}\z/i }, allow_blank: true

  def to_s
    self.name
  end

  def hex_color
    color.presence || '#0E487B'
  end

  # Locations double as implicit plant groups: water every non-archived plant here,
  # carrying forward each plant's last watering. Returns the created Watering records.
  def water_all!(at: Time.current)
    plants.where(archived: false).map { |plant| plant.quick_water!(at: at) }
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[name zone_id color]
  end
end
