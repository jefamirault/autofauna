class AddRecipeSourceToWaterings < ActiveRecord::Migration[8.0]
  def change
    add_reference :waterings, :recipe_source, null: true, foreign_key: true
  end
end
