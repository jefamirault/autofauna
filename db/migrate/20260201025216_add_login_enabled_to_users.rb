class AddLoginEnabledToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :login_enabled, :boolean, default: true, null: false
  end
end
