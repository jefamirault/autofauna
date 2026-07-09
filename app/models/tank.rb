class Tank < ApplicationRecord
  ACCEPTED_PICTURE_TYPES = %w[image/png image/jpeg image/webp image/gif].freeze
  MAX_PICTURE_SIZE = 20.megabytes

  # Cap displayed size; the original upload is kept in storage.
  PICTURE_VARIANT = { resize_to_limit: [800, 800] }.freeze
  PICTURE_THUMB_VARIANT = { resize_to_fill: [128, 128] }.freeze

  has_one_attached :picture

  belongs_to :location, optional: true
  has_one :zone, through: :location
  has_many :log_entries, as: :loggable, dependent: :destroy
  belongs_to :project
  has_many :water_tests, dependent: :destroy
  has_many :recipe_sources
  has_many :water_changes, dependent: :destroy
  has_many :feeding_instructions, dependent: :destroy
  has_many :equipment, dependent: :destroy

  validate :picture_must_be_valid, if: -> { picture.attached? }

  # True only when a *persisted* upload exists. After a failed save the new attachment is
  # staged with an unpersisted blob, which can't generate a variant URL — treat that as
  # "no picture" so the form/show can re-render validation errors instead of 500ing.
  def picture_attached?
    picture.attached? && picture.blob&.persisted?
  end

  def latest_water_test
    water_tests.recent.first
  end

  def water_tests_since(date)
    water_tests.where('tested_at >= ?', date)
  end

  def last_recorded_test_with_temperature
    water_tests
      .where("parameters ? 'temperature'")
      .where("parameters->>'temperature' IS NOT NULL")
      .where("parameters->>'temperature' != ''")
      .recent
      .first
  end

  def last_recorded_temperature
    last_recorded_test_with_temperature&.temperature
  end

  def last_recorded_temperature_with_unit
    test = water_tests
             .where("parameters ? 'temperature'")
             .where("parameters->>'temperature' IS NOT NULL")
             .where("parameters->>'temperature' != ''")
             .recent
             .first

    return nil unless test&.temperature
    "#{test.temperature.round(1)}°#{test.temperature_unit}"
  end
  def latest_ph
    latest_water_test&.ph
  end

  def parameter_history(param, limit = 10)
    water_tests.recent.limit(limit).where("parameters ? :param", param: param.to_s)
  end


  enum :capacity_units, {
    'gallons' => 0,
    'liters' => 1
  }

  def to_s
    self.name
  end

  def print_capacity
    return nil if self.capacity.nil?
    "#{sprintf('%g', self.capacity)} #{self.capacity_units}"
  end

  def last_tds
    # last_tds_reading&.tds
  end

  def last_tds_reading
    # tds_readings.sort{|r| r.datetime}.first
  end

  def last_water_change
    water_changes.recent.first
  end

  def water_change_schedule
    if water_change_min_days && water_change_max_days
      if water_change_min_days == water_change_max_days
        "Every #{water_change_min_days} days"
      else
        "Every #{water_change_min_days}–#{water_change_max_days} days"
      end
    elsif water_change_min_days
      "Every #{water_change_min_days}+ days"
    elsif water_change_max_days
      "Every #{water_change_max_days} days or less"
    end
  end

  private

  def picture_must_be_valid
    unless picture.content_type.in?(ACCEPTED_PICTURE_TYPES)
      errors.add(:picture, "must be a PNG, JPEG, WEBP, or GIF image")
    end

    if picture.byte_size.to_i > MAX_PICTURE_SIZE
      errors.add(:picture, "is too large (maximum 20MB)")
    end
  end
end
