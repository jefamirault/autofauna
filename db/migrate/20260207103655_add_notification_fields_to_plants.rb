class AddNotificationFieldsToPlants < ActiveRecord::Migration[8.0]
  def change
    add_column :plants, :notifications_enabled, :boolean, default: false, null: false
    add_column :plants, :last_notification_sent_at, :datetime
  end
end
