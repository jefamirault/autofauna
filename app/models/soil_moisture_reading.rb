class SoilMoistureReading < ApplicationRecord
  belongs_to :plant
  belongs_to :watering, optional: true

  enum :timing, { standalone: 0, pre_watering: 1, post_watering: 2 }
  enum :value_categorical, {
    saturated: 0,
    wet: 1,
    moist: 2,
    dry: 3,
    bone_dry: 4
  }

  validates :measured_at, presence: true
  validate :exactly_one_value_present
  validate :correct_value_type_for_project
  validates :value_numeric,
    numericality: true,
    if: -> { value_numeric.present? }

  before_validation :set_measured_at, on: :create

  scope :recent, -> { order(measured_at: :desc) }

  # Returns the appropriate value (numeric or categorical) as the actual value
  def value
    if value_numeric.present?
      value_numeric
    elsif value_categorical.present?
      value_categorical
    end
  end

  # Returns a human-readable display string
  def display_value
    if value_numeric.present?
      value_numeric.to_s
    elsif value_categorical.present?
      value_categorical.titleize
    else
      "N/A"
    end
  end

  private

  def set_measured_at
    self.measured_at ||= Time.current
  end

  def exactly_one_value_present
    if value_numeric.blank? && value_categorical.blank?
      errors.add(:base, "Must provide either numeric or categorical moisture value")
    elsif value_numeric.present? && value_categorical.present?
      errors.add(:base, "Cannot provide both numeric and categorical values")
    end
  end

  def correct_value_type_for_project
    return unless plant&.project

    if plant.project.moisture_measurement_type == 'numeric' && value_numeric.blank?
      errors.add(:value_numeric, "is required for this project's measurement type")
    elsif plant.project.moisture_measurement_type == 'categorical' && value_categorical.blank?
      errors.add(:value_categorical, "is required for this project's measurement type")
    end
  end
end
