class WaterChange < ApplicationRecord
  belongs_to :tank

  enum :volume_units, {
    'gallons' => 0,
    'liters' => 1
  }

  scope :recent, -> { order(changed_at: :desc) }

  def to_s
    changed_at ? changed_at.strftime('%B %d, %Y') : 'Water Change'
  end

  def print_volume
    return nil if volume.nil?
    "#{sprintf('%g', volume)} #{volume_units}"
  end
end
