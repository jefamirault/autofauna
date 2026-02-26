class Watering < ApplicationRecord
  belongs_to :plant
  belongs_to :recipe_batch, optional: true
  belongs_to :recipe, optional: true
  has_many :soil_moisture_readings, dependent: :nullify

  validates :watered_at, presence: true

  before_validation :set_recipe_from_batch

  after_save_commit :update_watering_intervals
  after_destroy :update_watering_intervals

  after_save_commit :update_last_watering
  after_destroy :update_last_watering

  after_save :create_moisture_readings,
    if: -> { @pre_moisture.present? || @post_moisture.present? }

  scope :recent, -> {
    order(watered_at: :desc, updated_at: :desc, )
  }
  enum :units, {
    'cups' => 0,
    'oz' => 1,
    'mL' => 2,
    'gal' => 3,
    'qt' => 4,
    'L' => 5
  }

  # interval: integer # of days between this watering and the last watering for the same plant
  def interval
    if super.nil?
      set_interval
    else
      super
    end
  end

  def set_interval
    current = plant.waterings.index self
    if current > 0
      prev_watering = plant.waterings[current - 1]
      self.interval = (self.watered_at.to_date - prev_watering.watered_at.to_date).to_i
    else
      # this is the first watering logged for this plant
      self.interval = -1
    end
    self.interval if save
  end

  def interval_text
    if interval >= 0
      "#{interval} #{I18n.t 'time.days'}"
    else
      "n/a"
    end
  end

  def self.create_from_json(json)
    w = Watering.new do |w|
      w.id = json['id']
      w.plant_id = json['plant_id']
      w.watered_at = json['watered_at'] || json['date']
      w.notes = json['notes']
      w.created_at = json['created_at']
      w.updated_at = json['updated_at']
    end
    w.save
    w
  end

  def print_volume
    return nil if self.volume.nil?
    "#{sprintf('%g', self.volume)} #{self.units} water"
  end

  def volume_and_notes
    "<strong>#{print_volume}</strong> #{self.notes.nil? || self.notes == '' ? '' : self.notes}".html_safe
  end

  # Virtual attributes for form integration
  attr_accessor :pre_moisture, :post_moisture, :pre_moisture_reading_id

  private

  def set_recipe_from_batch
    if recipe_batch.present? && recipe.blank?
      self.recipe = recipe_batch.recipe
    end
  end

  def update_watering_intervals
    # Skip if plant is being destroyed
    return if plant.destroyed?

    # created or deleted or watered_at changed
    if previous_changes[:id] || self.destroyed? || previous_changes[:watered_at]
      later_waterings = plant.waterings.reject(&:frozen?).select {|w| w.watered_at >= self.watered_at}
      later_waterings.each &:set_interval
    end
  end

  def update_last_watering
    # Skip if plant is being destroyed
    return if plant.destroyed?

    most_recent = plant.waterings.order(:watered_at).last
    watered_at_date = most_recent&.watered_at&.to_date
    unless plant.date_last_watering == watered_at_date
      plant.update date_last_watering: watered_at_date
    end
    unless plant.last_watering_id == most_recent&.id
      plant.update last_watering: most_recent
    end
    plant.update_watering_dates
  end

  def create_moisture_readings
    if @pre_moisture.present?
      # If pre_moisture_reading_id exists, link to existing reading instead of creating new
      if @pre_moisture_reading_id.present?
        link_existing_moisture_reading(@pre_moisture_reading_id, :pre_watering)
      else
        create_moisture_reading(:pre_watering, @pre_moisture)
      end
    end

    if @post_moisture.present?
      create_moisture_reading(:post_watering, @post_moisture)
    end
  end

  def link_existing_moisture_reading(reading_id, timing)
    reading = SoilMoistureReading.find_by(id: reading_id)
    return unless reading && reading.plant_id == plant_id

    # Update the existing standalone reading to link it to this watering
    reading.update!(
      watering: self,
      timing: timing,
      measured_at: watered_at
    )
  end

  def create_moisture_reading(timing, value)
    attrs = {
      plant: plant,
      watering: self,
      measured_at: watered_at,
      timing: timing
    }

    if plant.project.moisture_measurement_type == 'numeric'
      attrs[:value_numeric] = value.to_f
    else
      attrs[:value_categorical] =
        SoilMoistureReading.value_categoricals[value]
    end

    SoilMoistureReading.create!(attrs)
  end
end
