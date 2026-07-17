# Shared volume-unit enum mapping and conversion helpers for models that track a
# volume in one of the supported units (RecipeBatch, LocationSupply).
module VolumeConvertible
  extend ActiveSupport::Concern

  # Enum value map shared by every volume-tracking column. Use as
  # `enum :some_units, VolumeConvertible::VOLUME_UNITS`.
  VOLUME_UNITS = {
    'cups' => 0,
    'oz'   => 1,
    'mL'   => 2,
    'gal'  => 3,
    'qt'   => 4,
    'L'    => 5
  }.freeze

  UNITS_TO_ML = {
    'cups' => 236.588,
    'oz'   => 29.5735,
    'mL'   => 1.0,
    'gal'  => 3785.41,
    'qt'   => 946.353,
    'L'    => 1000.0
  }.freeze

  private

  def convert_to_ml(amount, units)
    factor = UNITS_TO_ML[units.to_s]
    return 0.0 unless factor
    amount.to_f * factor
  end

  def convert_volume(amount, from_units, to_units)
    ml = convert_to_ml(amount, from_units)
    to_factor = UNITS_TO_ML[to_units.to_s]
    return 0.0 unless to_factor
    ml / to_factor
  end
end
