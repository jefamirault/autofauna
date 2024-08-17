class SessionsController < ApplicationController
  def new
    @user = User.new
  end

  def create
    @user = User.authenticate_by(session_params)
    if @user.present?
      login @user if @user.present?
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
