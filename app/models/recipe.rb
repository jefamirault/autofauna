class Recipe < ApplicationRecord
  belongs_to :project

  has_many :recipe_ingredients, -> { order(:position) }, inverse_of: :recipe, dependent: :destroy
  has_many :recipe_sources, through: :recipe_ingredients
  has_many :recipe_batches, dependent: :destroy
  has_many :plants, dependent: :nullify
  has_many :waterings, dependent: :nullify

  accepts_nested_attributes_for :recipe_ingredients, allow_destroy: true, reject_if: :reject_ingredient

  validates :name, presence: true, uniqueness: { scope: :project_id }
  validates :color, format: { with: /\A#[0-9A-F]{6}\z/i }, allow_blank: true
  validate :unique_recipe_sources

  scope :pinned, -> { where(pinned: true) }

  def reject_ingredient(attributes)
    # Reject if all blank OR if no recipe_source_id is present
    attributes[:recipe_source_id].blank?
  end

  def unique_recipe_sources
    source_ids = recipe_ingredients.reject(&:marked_for_destruction?).map(&:recipe_source_id).compact
    if source_ids.uniq.length != source_ids.length
      errors.add(:base, "Cannot add the same source multiple times")
    end
  end

  def hex_color
    color.presence || '#7B1FA2'
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[id name color]
  end

  def to_s
    name
  end
end
