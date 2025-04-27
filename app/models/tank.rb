class Tank < ApplicationRecord
  has_many :tds_readings
  belongs_to :zone
  has_many :log_entries, as: :loggable, dependent: :destroy
  belongs_to :project

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
end
