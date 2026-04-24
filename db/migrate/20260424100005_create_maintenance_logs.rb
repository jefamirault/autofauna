class CreateMaintenanceLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :maintenance_logs do |t|
      t.references :equipment, null: false, foreign_key: true
      t.datetime :performed_at
      t.text :notes
      t.timestamps
    end
    add_index :maintenance_logs, :performed_at
  end
end
