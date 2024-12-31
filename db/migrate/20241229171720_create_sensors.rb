class CreateSensors < ActiveRecord::Migration[8.0]
  def change
    create_table :sensors do |t|
      t.string :name
      t.integer :zone_id
      t.string :location
      t.integer :project_id
      t.text :description

      t.timestamps
    end
  end
end
