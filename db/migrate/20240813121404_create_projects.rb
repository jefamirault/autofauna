class CreateProjects < ActiveRecord::Migration[7.1]
  def change
    add_column :plants, :project_id, :integer
    create_table :projects do |t|
      t.integer :owner_id
      t.string :name
      t.text :description
      t.boolean :active, default: true

      t.timestamps
    end
    create_table :collaborations do |t|
      t.integer :user_id
      t.integer :project_id
      t.integer :role
    end
  end
end
