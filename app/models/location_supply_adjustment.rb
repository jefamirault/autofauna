# An auditable entry in a LocationSupply's history: who changed the stock, how, and by how much.
class LocationSupplyAdjustment < ApplicationRecord
  belongs_to :location_supply
  belongs_to :user, optional: true

  enum :action, { add: 0, remove: 1, deplete: 2 }
  enum :units, VolumeConvertible::VOLUME_UNITS, prefix: :units
end
