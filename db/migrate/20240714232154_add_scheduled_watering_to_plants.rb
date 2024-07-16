class AddScheduledWateringToPlants < ActiveRecord::Migration[7.0]
  def change
    add_column :plants, :scheduled_watering, :date
  end
end
