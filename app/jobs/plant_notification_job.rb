class PlantNotificationJob < ApplicationJob
  queue_as :default

  def perform
    User.where(notification_enabled: true, guest: false).find_each do |user|
      next unless current_hour_matches?(user)

      plants = user.plants_needing_notification
      next if plants.empty?

      PlantNotificationMailer.watering_reminder(user, plants.to_a).deliver_later

      user.push_subscriptions.find_each do |subscription|
        plants.each do |plant|
          subscription.send_notification(
            title: "Water #{plant.name}",
            body: "#{plant.label} is due for watering",
            url: "/plants/#{plant.id}"
          )
        end
      end

      plants.each(&:mark_notification_sent!)
    end
  end

  private

  def current_hour_matches?(user)
    return true if user.notification_time.nil?

    user.notification_time.hour == Time.current.hour
  end
end
