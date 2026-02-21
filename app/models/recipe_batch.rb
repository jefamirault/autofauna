class RecipeBatch < ApplicationRecord
  belongs_to :project
  belongs_to :recipe
  has_many :waterings, dependent: :nullify

  validates :tds, presence: true, numericality: { greater_than: 0, only_integer: true }

  enum :volume_units, {
    'cups' => 0,
    'oz' => 1,
    'mL' => 2,
    'gal' => 3,
    'qt' => 4,
    'L' => 5
  }

  scope :active, -> { where(active: true) }

  def to_s
    "#{recipe.name} @ #{tds}ppm"
  end

  def label
    date_str = mixed_on ? mixed_on.strftime("%-b %-d") : created_at&.strftime("%-b %-d")
    "#{recipe.name} @ #{tds}ppm (#{date_str})"
  end
end
