class AddPinnedToRecipesAndRecipeSources < ActiveRecord::Migration[8.0]
  def change
    add_column :recipes, :pinned, :boolean, default: false, null: false
    add_column :recipe_sources, :pinned, :boolean, default: false, null: false
  end
end
