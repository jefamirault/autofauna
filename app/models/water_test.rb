class WaterTest < ApplicationRecord
  belongs_to :tank

  validates :parameters, presence: true
  validate :validate_parameter_values

  scope :recent, -> { order(tested_at: :desc) }
  scope :for_tank, ->(tank) { where(tank: tank) }
  scope :with_parameter, ->(param) { where("parameters ? :param", param: param.to_s) }

  before_validation :set_tested_at, if: -> { tested_at.blank? }

  # Parameter accessor methods
  def ph
    return nil if parameters['ph'] == ''
    parameters['ph']&.to_f
  end

  def ph=(value)
    parameters['ph'] = value
  end

  def tds
    return nil if parameters['tds'] == ''
    parameters['tds']&.to_i
  end

  def tds=(value)
    parameters['tds'] = value
  end

  def temperature
    return nil if parameters['temperature'] == ''
    parameters['temperature']&.to_f
  end

  def temperature=(value)
    parameters['temperature'] = value
  end

  def temperature_unit
    parameters['temperature_unit'] || 'F'
  end

  def temperature_unit=(value)
    parameters['temperature_unit'] = value
  end

  def nitrate
    return nil if parameters['nitrate'] == ''
    parameters['nitrate']&.to_f
  end

  def nitrate=(value)
    parameters['nitrate'] = value
  end

  def nitrite
    return nil if parameters['nitrite'] == ''
    parameters['nitrite']&.to_f
  end

  def nitrite=(value)
    parameters['nitrite'] = value
  end

  def ammonia
    return nil if parameters['ammonia'] == ''
    parameters['ammonia']&.to_f
  end

  def ammonia=(value)
    parameters['ammonia'] = value
  end

  def kh
    return nil if parameters['kh'] == ''
    parameters['kh']&.to_f
  end

  def kh=(value)
    parameters['kh'] = value
  end

  def gh
    return nil if parameters['gh'] == ''
    parameters['gh']&.to_f
  end

  def gh=(value)
    parameters['gh'] = value
  end

  def temperature_celsius
    return temperature if temperature_unit == 'C'
    (temperature - 32) * 5.0 / 9.0 if temperature
  end

  def temperature_fahrenheit
    return temperature if temperature_unit == 'F'
    (temperature * 9.0 / 5.0) + 32 if temperature
  end

  # Query helpers
  def self.ph_range(min, max)
    where("(parameters->>'ph')::float BETWEEN ? AND ?", min, max)
  end

  def self.temperature_above(temp, unit = 'F')
    if unit == 'F'
      where("(parameters->>'temperature')::float > ? AND parameters->>'temperature_unit' = 'F'", temp)
    else
      where("(parameters->>'temperature')::float > ? AND parameters->>'temperature_unit' = 'C'", temp)
    end
  end

  private

  def set_tested_at
    self.tested_at = Time.current
  end

  def validate_parameter_values
    if parameters['ph'].present?
      ph_val = parameters['ph'].to_f
      errors.add(:ph, 'must be between 0 and 14') unless ph_val.between?(0, 14)
    end

    if parameters['temperature_unit'].present?
      unless %w[F C].include?(parameters['temperature_unit'])
        errors.add(:temperature_unit, 'must be F or C')
      end
    end

    numeric_params = %w[tds temperature nitrate nitrite ammonia kh gh]
    numeric_params.each do |param|
      if parameters[param].present?
        value = parameters[param].to_f
        errors.add(param.to_sym, 'must be non-negative') if value < 0
      end
    end
  end
end
