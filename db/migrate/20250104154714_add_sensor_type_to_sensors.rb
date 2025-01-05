class AddSensorTypeToSensors < ActiveRecord::Migration[8.0]
  def change
    add_column :sensors, :sensor_type_id, :integer
  end
end
