class CreateLocationSupplies < ActiveRecord::Migration[8.0]
  def change
    create_table :location_supplies do |t|
      t.references :location, null: false, foreign_key: true
      t.references :supplyable, polymorphic: true, null: false
      t.float :quantity, null: false, default: 0.0
      t.integer :quantity_units

      t.timestamps
    end

    add_index :location_supplies, [:location_id, :supplyable_type, :supplyable_id],
              unique: true, name: "index_location_supplies_on_location_and_supplyable"

    create_table :location_supply_adjustments do |t|
      t.references :location_supply, null: false, foreign_key: true
      t.references :user, foreign_key: false, index: true
      t.integer :action, null: false
      t.float :amount, null: false, default: 0.0
      t.integer :units
      t.float :quantity_after
      t.text :note

      t.timestamps
    end
  end
end
