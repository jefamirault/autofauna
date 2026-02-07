class PlantNotificationMailer < ApplicationMailer
  def watering_reminder(user, plants)
    @user = user
    @plants = plants
    mail(to: user.email, subject: "#{plants.size} plant#{'s' if plants.size > 1} need watering")
  end
end
