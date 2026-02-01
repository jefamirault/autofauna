class SettingsController < ApplicationController
  before_action :authenticate

  def index
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
end
