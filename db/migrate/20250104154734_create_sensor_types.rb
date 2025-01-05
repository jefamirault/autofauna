class CreateSensorTypes < ActiveRecord::Migration[8.0]
  def change
    create_table :sensor_types do |t|
      t.string :name
      t.integer :min_temp
      t.integer :max_temp
      t.integer :min_humidity
      t.integer :max_humidity
      t.float :accuracy_temp
      t.float :resolution_temp
      t.float :accuracy_humidity
      t.float :resolution_humidity

      t.timestamps
    end
  end
end
