class SessionsController < ApplicationController
  skip_before_action :require_onboarding

  rate_limit to: 10, within: 3.minutes, only: :create,
             store: RateLimiting::STORE, with: -> { rate_limit_exceeded }
  rate_limit to: 10, within: 3.minutes, only: :create, name: "email",
             by: -> { params.dig(:user, :email).to_s.downcase.presence || request.remote_ip },
             store: RateLimiting::STORE, with: -> { rate_limit_exceeded }

  def new
    @user = User.new
  end

  def create
    @user = User.authenticate_by(session_params)
    if @user.present? && !@user.login_enabled?
      flash[:alert] = t('errors.account_disabled')
      render :new, status: :unprocessable_entity
    elsif @user.present?
      login @user
      auto_select_project(@user)
      redirect_to plants_path, notice: t('account.sign_in_success')
    else
      flash[:alert] = t('errors.invalid_email_or_password')
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    logout
  end

  private

  def session_params
    params.require(:user).permit(:email, :password)
  end
end
