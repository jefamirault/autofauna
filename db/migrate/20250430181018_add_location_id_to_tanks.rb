class AddLocationIdToTanks < ActiveRecord::Migration[8.0]
  def change
    add_column :tanks, :location_id, :integer
    remove_column :tanks, :location, :string
    remove_column :tanks, :zone_id, :integer
  end
end
