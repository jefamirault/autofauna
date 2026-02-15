class CreateRecipes < ActiveRecord::Migration[8.0]
  def change
    create_table :recipes do |t|
      t.references :project, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description

      t.timestamps
    end

    add_index :recipes, [:project_id, :name], unique: true
  end
end
