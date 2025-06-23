class CreateWaterTests < ActiveRecord::Migration[7.0]
  def change
    create_table :water_tests do |t|
      t.references :tank, null: false, foreign_key: true
      t.jsonb :parameters, null: false, default: {}
      t.datetime :tested_at
      t.text :notes

      t.timestamps
    end

    add_index :water_tests, :tested_at
    add_index :water_tests, :parameters, using: :gin

  # populate water_tests with TDS Readings
    count = 0
    total = TdsReading.count
    TdsReading.all.each do |r|
      if r.tank_id && r.tds
        if WaterTest.create tank_id: r.tank_id, parameters: { tds: r.tds }, tested_at: r.datetime
          count += 1
        end
      end
    end
    puts "Migrated #{count} out of #{total} TDS Readings"

  # delete TDS readings
    drop_table :tds_readings
  end
end