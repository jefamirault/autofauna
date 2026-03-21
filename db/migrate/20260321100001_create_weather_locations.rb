class CreateWeatherLocations < ActiveRecord::Migration[8.0]
  def change
    create_table :weather_locations do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name
      t.decimal :latitude, precision: 9, scale: 4, null: false
      t.decimal :longitude, precision: 9, scale: 4, null: false
      t.string :zip
      t.string :location_name
      t.boolean :primary, default: false, null: false

      t.timestamps
    end

    add_index :weather_locations, [:user_id, :primary]
  end
end
