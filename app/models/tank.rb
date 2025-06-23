class Tank < ApplicationRecord
  belongs_to :location
  has_one :zone, through: :location
  has_many :log_entries, as: :loggable, dependent: :destroy
  belongs_to :project
  has_many :water_tests, dependent: :destroy

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
end
