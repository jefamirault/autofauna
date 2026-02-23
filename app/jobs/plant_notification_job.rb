class PlantNotificationJob < ApplicationJob
  queue_as :default

  def perform
    config = NotificationConfig.instance
    return if config.notifications_paused?

    User.where(guest: false)
        .where("email_notifications_enabled = ? OR push_notifications_enabled = ?", true, true)
        .find_each do |user|
      send_email = user.should_send_notification?(:email) && user.plants_needing_water.any?
      send_push = user.should_send_notification?(:push) && user.plants_needing_water.any?
      next unless send_email || send_push
      SendUserNotificationJob.perform_later(user.id, send_email, send_push)
    end
  end
end
