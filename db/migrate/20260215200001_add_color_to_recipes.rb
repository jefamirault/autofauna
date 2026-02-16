class AddColorToRecipes < ActiveRecord::Migration[8.0]
  def change
    add_column :recipes, :color, :string, default: '#7B1FA2'
  end
end
