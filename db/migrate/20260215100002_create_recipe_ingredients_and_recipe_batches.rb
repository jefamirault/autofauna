class CreateRecipeIngredientsAndRecipeBatches < ActiveRecord::Migration[8.0]
  def change
    create_table :recipe_ingredients do |t|
      t.references :recipe, null: false, foreign_key: true
      t.references :recipe_source, null: false, foreign_key: true
      t.decimal :amount, precision: 10, scale: 4
      t.string :units
      t.integer :position

      t.timestamps
    end

    add_index :recipe_ingredients, [:recipe_id, :recipe_source_id], unique: true

    create_table :recipe_batches do |t|
      t.references :project, null: false, foreign_key: true
      t.references :recipe, null: false, foreign_key: true
      t.integer :tds
      t.float :volume
      t.integer :volume_units
      t.date :mixed_on
      t.text :notes
      t.boolean :active, default: true

      t.timestamps
    end
  end
end
