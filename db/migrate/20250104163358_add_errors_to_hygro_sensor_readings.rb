class AddErrorsToHygroSensorReadings < ActiveRecord::Migration[8.0]
  def change
    add_column :hygro_sensor_readings, :error, :string, null: true, default: nil
  end
end
