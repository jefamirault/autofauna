class AddAdvancedModeToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :advanced_mode, :boolean, default: false
  end
end
