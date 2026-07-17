class RecipeBatch < ApplicationRecord
  include VolumeConvertible

  belongs_to :project
  belongs_to :recipe
  has_many :waterings, dependent: :nullify

  validates :tds, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :remaining_volume, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  enum :volume_units, VolumeConvertible::VOLUME_UNITS

  scope :active, -> { where(active: true) }

  USAGE_WINDOW_DAYS = 30

  def to_s
    "#{recipe.name} @ #{tds}ppm"
  end

  def label
    date_str = mixed_on ? mixed_on.strftime("%-b %-d") : created_at&.strftime("%-b %-d")
    "#{recipe.name} @ #{tds}ppm (#{date_str})"
  end

  def remaining_percent
    return nil unless volume.present? && volume > 0 && remaining_volume.present?
    (remaining_volume / volume * 100).round(1)
  end

  # Rolling usage per day over the last USAGE_WINDOW_DAYS days, in volume_units
  def usage_per_day
    recent = waterings
      .where.not(volume: nil)
      .where("watered_at >= ?", USAGE_WINDOW_DAYS.days.ago)

    total_ml = recent.sum do |w|
      convert_to_ml(w.volume, w.units)
    end

    batch_ml = convert_to_ml(1.0, volume_units) # 1 unit in volume_units -> mL
    total_in_units = total_ml / batch_ml
    total_in_units / USAGE_WINDOW_DAYS
  end

  # Returns projected run-out Date or nil if no usage data
  def projected_runout
    return nil unless remaining_volume.present? && remaining_volume > 0

    rate = usage_per_day
    return nil if rate.nil? || rate <= 0

    days_left = remaining_volume / rate
    Date.current + days_left.ceil.days
  end

  def replenishment_urgency
    runout = projected_runout
    return :no_usage unless runout

    days = (runout - Date.current).to_i
    if days <= 3
      :critical
    elsif days <= 7
      :soon
    else
      :ok
    end
  end

  def decrement_remaining!(volume_used, units_used)
    return unless remaining_volume.present?

    used_in_batch_units = convert_volume(volume_used.to_f, units_used, volume_units)
    new_remaining = [remaining_volume - used_in_batch_units, 0].max
    update!(remaining_volume: new_remaining, last_adjusted_at: Time.current)
  end

  def increment_remaining!(volume_added, units_added)
    added_in_batch_units = convert_volume(volume_added.to_f, units_added, volume_units)
    current = remaining_volume || 0
    new_remaining = current + added_in_batch_units
    new_remaining = [new_remaining, volume].min if volume.present?
    update!(remaining_volume: new_remaining, last_adjusted_at: Time.current)
  end
end
