class PlantGroup < ApplicationRecord
  belongs_to :project
  has_many :plant_group_memberships, dependent: :destroy
  has_many :plants, through: :plant_group_memberships

  validates_presence_of :name
  validates :color, format: { with: /\A#[0-9A-F]{6}\z/i }, allow_blank: true

  def to_s
    name
  end

  def hex_color
    color.presence || '#0E487B'
  end

  def watering_frequency_text
    return '' if min_watering_freq.nil? && max_watering_freq.nil?
    if min_watering_freq == max_watering_freq
      "Every #{min_watering_freq} day#{min_watering_freq == 1 ? '' : 's'}"
    else
      "#{min_watering_freq} - #{max_watering_freq} days"
    end
  end

  # Water every non-archived member, carrying forward each plant's last watering.
  # Returns the created Watering records.
  def water_all!(at: Time.current)
    plants.where(archived: false).map { |plant| plant.quick_water!(at: at) }
  end

  # Push this group's shared watering schedule onto its members (opt-in from the form).
  def apply_schedule_to_members!
    return if min_watering_freq.blank? && max_watering_freq.blank?
    plants.find_each do |plant|
      plant.update!(min_watering_freq: min_watering_freq, max_watering_freq: max_watering_freq)
    end
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[name color]
  end
end
