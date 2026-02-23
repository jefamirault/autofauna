class SettingsController < ApplicationController
  before_action :authenticate

  def index
  end

  def update
    if current_user.update(notification_params)
      redirect_to settings_path, notice: "Notification preferences saved."
    else
      redirect_to settings_path, alert: "Could not save notification preferences."
    end
  end

  def destroy
    if current_user.authenticate(params[:password])
      current_user.update!(login_enabled: false)
      DeleteUserDataJob.perform_later(current_user.id)
      Current.project = nil
      Current.user = nil
      reset_session
      cookies.delete :project_id
      cookies.delete :user_id
      redirect_to new_session_path, notice: t('account.delete_account_success')
    else
      redirect_to settings_path, alert: t('account.incorrect_password')
    end
  end

  def english
    cookies[:locale] = :en
    redirect_to root_path
  end

  def spanish
    cookies[:locale] = :es
    redirect_to root_path
  end

  def toggle_notification
    channel = params[:channel]
    return head(:bad_request) unless %w[email push].include?(channel)

    field = "#{channel}_notifications_enabled"
    current_user.update_column(field.to_sym, !current_user.send("#{field}?"))
    head :ok
  end

  def disable_all_notifications
    current_user.update_columns(email_notifications_enabled: false, push_notifications_enabled: false)
    redirect_to settings_path, notice: "All notifications disabled."
  end

  def send_test_email
    if current_user.plants.any?
      # Send test email with up to 3 plants as examples
      plants = current_user.plants.limit(3)
      PlantNotificationMailer.watering_reminder(current_user, plants.to_a).deliver_later
      redirect_to settings_path, notice: "Test email sent! Check your inbox at #{current_user.email}"
    else
      redirect_to settings_path, alert: "You need at least one plant to send a test email notification."
    end
  end

  def send_test_push
    if current_user.push_subscriptions.enabled.any?
      sent_count = 0
      current_user.push_subscriptions.enabled.each do |subscription|
        begin
          subscription.send_notification(
            title: "Test Notification from Autofauna",
            body: "Your push notifications are working! You'll receive plant watering reminders here.",
            url: "/plants"
          )
          sent_count += 1
        rescue => e
          Rails.logger.error "Failed to send test push notification: #{e.message}"
        end
      end

      if sent_count > 0
        redirect_to settings_path, notice: "Test push notification sent to #{sent_count} device(s)!"
      else
        redirect_to settings_path, alert: "Failed to send test push notifications. Your subscriptions may be expired."
      end
    else
      redirect_to settings_path, alert: "You need to enable push notifications first. Click 'Enable Push Notifications' above."
    end
  end

  private

  def notification_params
    params.require(:user).permit(
      :email_notifications_enabled, :push_notifications_enabled,
      :email_notification_time, :push_notification_time,
      :email_notification_frequency_type, :email_notification_frequency_value,
      :push_notification_frequency_type, :push_notification_frequency_value
    )
  end
end
