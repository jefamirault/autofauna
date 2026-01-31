class AddShareTokenToPlants < ActiveRecord::Migration[8.0]
  def change
    add_column :plants, :share_token, :string
    add_index :plants, :share_token, unique: true
  end
end
