class PlantNotificationMailer < ApplicationMailer
  def watering_reminder(user, plants, config = nil)
    @user = user
    @plants = plants
    config ||= NotificationConfig.instance

    @body = config.render_email_body(user: user, plants: plants)
    subject = config.render_email_subject(count: plants.size)

    mail(to: user.email, subject: subject)
  end
end
