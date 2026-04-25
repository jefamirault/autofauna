class MaintenanceLog < ApplicationRecord
  belongs_to :equipment

  scope :recent, -> { order(performed_at: :desc) }

  def to_s
    performed_at ? performed_at.strftime('%B %d, %Y') : 'Maintenance'
  end
end
