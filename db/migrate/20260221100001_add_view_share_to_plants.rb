class AddViewShareToPlants < ActiveRecord::Migration[8.0]
  def change
    add_column :plants, :view_share_token, :string
    add_column :plants, :view_share_enabled, :boolean, default: false
    add_index :plants, :view_share_token, unique: true
  end
end
