class RefactorNotificationColumns < ActiveRecord::Migration[8.0]
  def change
    # Remove per-plant notification tracking (now handled at account level)
    remove_column :plants, :notifications_enabled, :boolean, default: false, null: false
    remove_column :plants, :last_notification_sent_at, :datetime

    # Remove old unified notification fields from users
    remove_column :users, :notification_enabled, :boolean, default: false, null: false
    remove_column :users, :notification_time, :time, default: "2000-01-01 09:00:00"

    # Add per-channel notification time
    add_column :users, :email_notification_time, :time, default: "2000-01-01 09:00:00"
    add_column :users, :push_notification_time, :time, default: "2000-01-01 09:00:00"

    # Add frequency settings per channel
    add_column :users, :email_notification_frequency_type, :string, default: "daily"
    add_column :users, :email_notification_frequency_value, :integer, default: 1
    add_column :users, :push_notification_frequency_type, :string, default: "daily"
    add_column :users, :push_notification_frequency_value, :integer, default: 1

    # Add last-sent tracking per channel
    add_column :users, :last_email_notification_sent_at, :datetime
    add_column :users, :last_push_notification_sent_at, :datetime
  end
end
