class CreateSoilMoistureReadings < ActiveRecord::Migration[8.0]
  def change
    create_table :soil_moisture_readings do |t|
      t.references :plant, null: false, foreign_key: true
      t.references :watering, null: true, foreign_key: true
      t.datetime :measured_at, null: false

      # Only one of these populated based on project.moisture_measurement_type
      t.decimal :value_numeric, precision: 5, scale: 2
      t.integer :value_categorical  # Enum: 0=Saturated, 1=Wet, 2=Moist, 3=Dry, 4=Bone Dry

      t.integer :timing, default: 0, null: false  # Enum: 0=standalone, 1=pre_watering, 2=post_watering
      t.text :notes
      t.timestamps
    end

    add_index :soil_moisture_readings, :measured_at
    add_index :soil_moisture_readings, [:plant_id, :measured_at]
    add_index :soil_moisture_readings, :timing
  end
end
