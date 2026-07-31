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

  # The plants that appear on this location's diagram. Archived plants are excluded here
  # the same way they are from `water_all!` and the locations index count.
  def diagram_plants
    plants.where(archived: false)
  end

  # True once at least one plant has been dropped on the canvas — drives whether the
  # locations index shows a mini-diagram or falls back to the photo/plain card.
  def layout?
    diagram_plants.where.not(layout_x: nil).where.not(layout_y: nil).exists?
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
