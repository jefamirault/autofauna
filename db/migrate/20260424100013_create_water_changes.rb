class CreateWaterChanges < ActiveRecord::Migration[8.0]
  def change
    create_table :water_changes do |t|
      t.references :tank, null: false, foreign_key: true
      t.datetime :changed_at
      t.float :percentage
      t.float :volume
      t.integer :volume_units
      t.text :notes
      t.timestamps
    end
    add_index :water_changes, :changed_at
  end
end
