class FeedingInstruction < ApplicationRecord
  belongs_to :tank

  validates :food_name, presence: true

  def to_s
    parts = [food_name]
    parts << "#{amount} #{unit}".strip if amount.present?
    parts << frequency if frequency.present?
    parts.join(' — ')
  end
end
