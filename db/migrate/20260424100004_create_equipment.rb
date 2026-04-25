class CreateEquipment < ActiveRecord::Migration[8.0]
  def change
    create_table :equipment do |t|
      t.references :tank, null: false, foreign_key: true
      t.string :name
      t.text :maintenance_instructions
      t.integer :maintenance_interval_days
      t.timestamps
    end
  end
end
