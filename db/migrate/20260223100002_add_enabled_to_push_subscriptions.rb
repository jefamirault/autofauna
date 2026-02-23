class AddEnabledToPushSubscriptions < ActiveRecord::Migration[8.0]
  def change
    add_column :push_subscriptions, :enabled, :boolean, default: true, null: false
  end
end
