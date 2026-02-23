module Admin
  class NotificationsController < ApplicationController
    before_action :authenticate
    before_action :authorize_admin

    def index
      @config = NotificationConfig.instance
      @users = User.where(guest: false).order(:email)
    end

    def update_config
      @config = NotificationConfig.instance
      if @config.update(config_params)
        redirect_to admin_notifications_path, notice: "Notification settings updated."
      else
        @users = User.where(guest: false).order(:email)
        render :index, status: :unprocessable_entity
      end
    end

    def update_user
      @user = User.find(params[:id])
      @user.update!(user_params)
      redirect_to admin_notifications_path, notice: "User notification settings updated."
    end

    private

    def config_params
      params.require(:notification_config).permit(
        :cron_expression,
        :notifications_paused,
        :email_subject_template,
        :email_body_template,
        :push_title_template,
        :push_body_template
      )
    end

    def user_params
      params.require(:user).permit(:email_notifications_enabled, :push_notifications_enabled)
    end
  end
end
