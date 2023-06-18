class CreateWaterings < ActiveRecord::Migration[7.0]
  def change
    create_table :waterings do |t|
      t.integer :plant_id
      t.date :date
      t.string :notes

      t.timestamps
    end
  end
end
