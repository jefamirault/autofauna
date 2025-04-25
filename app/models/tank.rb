class Tank < ApplicationRecord
  has_many :tds_readings
  belongs_to :zone
  has_many :log_entries, as: :loggable, dependent: :destroy

  def to_s
    self.name
  end
end
