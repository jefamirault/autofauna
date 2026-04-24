class CreateSavedSearches < ActiveRecord::Migration[8.0]
  def change
    create_table :saved_searches do |t|
      t.bigint :user_id, null: false
      t.bigint :project_id, null: false
      t.string :name, null: false
      t.string :query_term, null: false
      t.timestamps
    end
    add_index :saved_searches, [:user_id, :project_id]
    add_foreign_key :saved_searches, :users
    add_foreign_key :saved_searches, :projects
  end
end
