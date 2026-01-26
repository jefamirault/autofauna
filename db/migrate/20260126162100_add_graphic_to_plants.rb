class AddGraphicToPlants < ActiveRecord::Migration[8.0]
  def change
    add_column :plants, :graphic, :string
  end
end
