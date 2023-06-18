class CreatePlants < ActiveRecord::Migration[7.0]
  def change
    create_table :plants do |t|
      t.string :name
      t.integer :uid
      t.string :location
      t.string :pot

      t.timestamps
    end
  end
end
