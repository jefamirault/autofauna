class AddRecipeFieldsToWateringsAndPlants < ActiveRecord::Migration[8.0]
  def change
    add_reference :plants, :recipe, foreign_key: true
    add_column :waterings, :tds, :integer
    add_reference :waterings, :recipe_batch, foreign_key: true
    add_reference :waterings, :recipe, foreign_key: true
  end
end
