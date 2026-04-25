class Equipment < ApplicationRecord
  belongs_to :tank
  has_many :maintenance_logs, dependent: :destroy

  validates :name, presence: true

  def to_s
    name
  end

  def last_maintenance
    maintenance_logs.order(performed_at: :desc).first
  end

  def next_maintenance_due
    return nil unless maintenance_interval_days && last_maintenance
    last_maintenance.performed_at + maintenance_interval_days.days
  end

  def maintenance_overdue?
    return false unless next_maintenance_due
    next_maintenance_due < Time.current
  end

  def maintenance_interval_text
    return nil unless maintenance_interval_days
    if maintenance_interval_days % 30 == 0
      months = maintenance_interval_days / 30
      "#{months}x/month"
    elsif maintenance_interval_days % 7 == 0
      weeks = maintenance_interval_days / 7
      "#{weeks}x/week"
    else
      "every #{maintenance_interval_days} days"
    end
  end
end
