class CreateLogEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :log_entries do |t|
      t.string :entry_type
      t.text :description
      t.references :loggable, polymorphic: true, null: false
      t.references :user, null: false, foreign_key: true
      t.datetime :timestamp

      t.timestamps
    end
  end
end
