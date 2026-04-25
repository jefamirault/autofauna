class PlantRecipe < ApplicationRecord
  belongs_to :plant
  belongs_to :recipe

  validates :recipe_id, uniqueness: { scope: :plant_id }
end
