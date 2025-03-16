class CreateTdsReadings < ActiveRecord::Migration[8.0]
  def change
    create_table :tds_readings do |t|
      t.datetime :datetime
      t.integer :tank_id
      t.integer :tds

      t.timestamps
    end
  end
end
