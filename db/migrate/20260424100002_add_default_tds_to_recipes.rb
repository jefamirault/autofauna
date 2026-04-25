class AddDefaultTdsToRecipes < ActiveRecord::Migration[8.0]
  def change
    add_column :recipes, :default_tds, :integer
  end
end
