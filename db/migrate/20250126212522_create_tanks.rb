class CreateTanks < ActiveRecord::Migration[8.0]
  def change
    create_table :tanks do |t|
      t.string :name
      t.text :description
      t.integer :zone_id
      t.string :location

      t.timestamps
    end
  end
end
