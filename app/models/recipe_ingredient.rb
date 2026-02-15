class RecipeIngredient < ApplicationRecord
  belongs_to :recipe
  belongs_to :recipe_source

  validates :recipe_source_id, uniqueness: { scope: :recipe_id }

  def to_s
    "#{recipe_source} #{amount} #{units}".strip
  end
end
