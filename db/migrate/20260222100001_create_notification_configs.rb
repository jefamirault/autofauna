class CreateNotificationConfigs < ActiveRecord::Migration[8.0]
  def change
    create_table :notification_configs do |t|
      t.string :cron_expression, default: "0 * * * *", null: false
      t.boolean :notifications_paused, default: false, null: false
      t.string :email_subject_template, default: "{{count}} plant(s) need watering", null: false
      t.text :email_body_template, null: false
      t.string :push_title_template, default: "Water {{plant_name}}", null: false
      t.string :push_body_template, default: "{{plant_label}} is due for watering", null: false

      t.timestamps
    end
  end
end
