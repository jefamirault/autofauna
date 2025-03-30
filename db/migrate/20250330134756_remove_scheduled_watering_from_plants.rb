class RemoveScheduledWateringFromPlants < ActiveRecord::Migration[8.0]
  def change
    remove_column :plants, :date_scheduled_watering, :date
    remove_column :plants, :scheduled_watering_id, :integer
    remove_index :plants, :scheduled_watering_id if index_exists?(:plants, :scheduled_watering_id)
    remove_column :waterings, :fulfilled, :boolean
  end
end
