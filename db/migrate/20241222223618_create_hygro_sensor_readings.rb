class CreateHygroSensorReadings < ActiveRecord::Migration[8.0]
  def change
    create_table :hygro_sensor_readings do |t|
      t.datetime :datetime
      t.integer :temperature
      t.integer :humidity
      t.integer :project_id

      t.timestamps
    end
  end
end
