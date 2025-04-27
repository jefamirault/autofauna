class AddCapacityToTanks < ActiveRecord::Migration[8.0]
  def change
    add_column :tanks, :capacity, :float
    add_column :tanks, :capacity_units, :integer
  end
end
