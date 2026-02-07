class AddNotificationPreferencesToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :notification_enabled, :boolean, default: false, null: false
    add_column :users, :notification_time, :time, default: "09:00"
  end
end
