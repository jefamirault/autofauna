class AddWateringDateColumnsToPlants < ActiveRecord::Migration[7.1]
  def change
    add_column :plants, :date_min_watering, :date
    add_column :plants, :date_max_watering, :date
    add_column :plants, :date_sort_watering, :date
  end
end
