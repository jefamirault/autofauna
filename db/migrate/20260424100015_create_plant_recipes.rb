class CreatePlantRecipes < ActiveRecord::Migration[8.0]
  def change
    create_table :plant_recipes do |t|
      t.references :plant, null: false, foreign_key: true
      t.references :recipe, null: false, foreign_key: true
      t.integer :position, default: 0
      t.timestamps
    end

    add_index :plant_recipes, [:plant_id, :recipe_id], unique: true

    # Migrate existing recipe_id values from plants into the join table
    reversible do |dir|
      dir.up do
        execute <<~SQL
          INSERT INTO plant_recipes (plant_id, recipe_id, position, created_at, updated_at)
          SELECT id, recipe_id, 0, NOW(), NOW()
          FROM plants
          WHERE recipe_id IS NOT NULL
        SQL
      end
    end

    # Keep recipe_id on plants for now as a cached "primary recipe" reference
    # (used by Ransack filters and existing index queries)
  end
end
