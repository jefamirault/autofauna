class RecipeSource < ApplicationRecord
  belongs_to :project
  belongs_to :tank, optional: true

  has_many :recipe_ingredients, dependent: :destroy
  has_many :recipes, through: :recipe_ingredients

  validates :name, presence: true, uniqueness: { scope: :project_id }

  def to_s
    name
  end
end
