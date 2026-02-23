class AddNotificationChannelsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :email_notifications_enabled, :boolean, default: true, null: false
    add_column :users, :push_notifications_enabled, :boolean, default: true, null: false
  end
end
