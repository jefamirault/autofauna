class AddZonesToPlants < ActiveRecord::Migration[8.0]
  def change
    add_column :plants, :zone_id, :integer
  end
end
