class CreateZones < ActiveRecord::Migration[8.0]
  def change
    create_table :zones do |t|
      t.string :name
      t.integer :project_id
      t.text :description

      t.timestamps
    end
  end
end
