class CreateRecipeSources < ActiveRecord::Migration[8.0]
  def change
    create_table :recipe_sources do |t|
      t.references :project, null: false, foreign_key: true
      t.string :name, null: false
      t.references :tank, foreign_key: true
      t.text :description

      t.timestamps
    end

    add_index :recipe_sources, [:project_id, :name], unique: true
  end
end
