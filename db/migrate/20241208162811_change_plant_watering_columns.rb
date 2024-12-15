class ChangePlantWateringColumns < ActiveRecord::Migration[7.1]
  def change
    # scheduled_watering and last_watering each become a has_one
    rename_column :plants, :scheduled_watering, :date_scheduled_watering
    # cache the dates
    add_column :plants, :scheduled_watering_id, :integer
    # Fast lookup
    add_index :plants, :scheduled_watering_id

    add_column :plants, :date_last_watering, :date
    add_column :plants, :last_watering_id, :integer
    add_index :plants, :last_watering_id

    # allow create waterings
    add_column :waterings, :fulfilled, :boolean, default: true, null: false
  end
end
