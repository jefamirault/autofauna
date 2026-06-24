class CreatePlantGroups < ActiveRecord::Migration[8.0]
  def change
    create_table :plant_groups do |t|
      t.string :name, null: false
      t.string :color, default: "#0E487B"
      t.references :project, null: false, foreign_key: true
      t.integer :min_watering_freq
      t.integer :max_watering_freq

      t.timestamps
    end

    create_table :plant_group_memberships do |t|
      t.references :plant, null: false, foreign_key: true
      t.references :plant_group, null: false, foreign_key: true

      t.timestamps
    end

    add_index :plant_group_memberships, [:plant_id, :plant_group_id], unique: true,
      name: "index_plant_group_memberships_on_plant_and_group"
  end
end
