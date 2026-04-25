class CreateFeedingInstructions < ActiveRecord::Migration[8.0]
  def change
    create_table :feeding_instructions do |t|
      t.references :tank, null: false, foreign_key: true
      t.string :food_name
      t.string :amount
      t.string :unit
      t.string :frequency
      t.text :notes
      t.timestamps
    end
  end
end
