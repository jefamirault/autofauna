class SendUserNotificationJob < ApplicationJob
  queue_as :default

  def perform(user_id, send_email = true, send_push = true)
    config = NotificationConfig.instance
    return if config.notifications_paused?

    user = User.find_by(id: user_id)
    return unless user

    plants = user.plants_needing_water
    return if plants.empty?

    if send_email && user.email_notifications_enabled?
      PlantNotificationMailer.watering_reminder(user, plants.to_a, config).deliver_later
      user.update_column(:last_email_notification_sent_at, Time.current)
    end

    if send_push && user.push_notifications_enabled?
      title = "#{plants.size} plant#{'s' if plants.size > 1} need water"
      body = plants.map(&:name).first(5).join(", ")
      body += "..." if plants.size > 5
      user.push_subscriptions.enabled.find_each do |subscription|
        subscription.send_notification(title: title, body: body, url: "/plants")
      end
      user.update_column(:last_push_notification_sent_at, Time.current)
    end
  end
end
