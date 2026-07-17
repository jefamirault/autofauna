# A per-location stocking ledger for a water/fertilizer supply. `supplyable` is either a
# RecipeSource (a plain source like RO water) or a RecipeBatch (a mixed fertilizer).
#
# INDEPENDENT POOLS: this quantity is maintained manually by the user and is NOT synced with
# RecipeBatch#remaining_volume — watering plants does not decrement location stock, and vice
# versa. A batch mixed elsewhere and carried to a location is a physical transfer the user logs
# explicitly. See docs / agent_log for the rationale.
class LocationSupply < ApplicationRecord
  include VolumeConvertible

  SUPPLYABLE_TYPES = %w[RecipeSource RecipeBatch].freeze

  belongs_to :location
  belongs_to :supplyable, polymorphic: true
  has_many :location_supply_adjustments, dependent: :destroy

  enum :quantity_units, VolumeConvertible::VOLUME_UNITS

  validates :quantity, numericality: { greater_than_or_equal_to: 0 }
  validates :supplyable_type, inclusion: { in: SUPPLYABLE_TYPES }
  validates :supplyable_id, uniqueness: { scope: [:location_id, :supplyable_type] }

  # Add `amount` (in `units`) to the stock, converting into this supply's canonical units.
  def add!(amount, units = quantity_units, user: nil, note: nil)
    added = convert_volume(amount.to_f, units, quantity_units)
    transaction do
      update!(quantity: quantity + added)
      record_adjustment!(:add, amount, units, user, note)
    end
  end

  # Remove `amount` (in `units`), clamping the stock at zero.
  def remove!(amount, units = quantity_units, user: nil, note: nil)
    removed = convert_volume(amount.to_f, units, quantity_units)
    transaction do
      update!(quantity: [quantity - removed, 0].max)
      record_adjustment!(:remove, amount, units, user, note)
    end
  end

  # Mark the supply fully depleted (quantity -> 0), recording the amount that was on hand.
  def deplete!(user: nil, note: nil)
    transaction do
      prior = quantity
      update!(quantity: 0)
      record_adjustment!(:deplete, prior, quantity_units, user, note)
    end
  end

  def to_s
    supplyable.to_s
  end

  private

  def record_adjustment!(action, amount, units, user, note)
    location_supply_adjustments.create!(
      action: action,
      amount: amount.to_f.abs,
      units: units.to_s,
      quantity_after: quantity,
      user: user,
      note: note.presence
    )
  end
end
