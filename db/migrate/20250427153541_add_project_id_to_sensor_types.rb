class AddProjectIdToSensorTypes < ActiveRecord::Migration[8.0]
  def change
    add_column :sensor_types, :project_id, :integer
  end
end
