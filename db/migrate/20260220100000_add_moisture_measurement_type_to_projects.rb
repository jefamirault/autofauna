class AddMoistureMeasurementTypeToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :moisture_measurement_type, :integer, default: 0, null: false
    add_index :projects, :moisture_measurement_type
  end
end
