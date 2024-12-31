class AddSensorIdToHygroSensorReadings < ActiveRecord::Migration[8.0]
  def change
    add_column :hygro_sensor_readings, :sensor_id, :integer
  end
end
