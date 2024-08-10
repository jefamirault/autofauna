class SessionsController < ApplicationController
  def new
    @user = User.new
  end

  def create
    @user = User.authenticate_by(session_params)
    if @user.present?
      login @user if @user.present?
      redirect_to plants_path, notice: "Signed in successfully."
    else
      flash[:alert] = 'Invalid email or password.'
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    Current.user = nil
    reset_session
    cookies.delete :user_id
    redirect_to new_session_path, notice: "You have been logged out."
  end

  private

  def session_params
    params.require(:user).permit(:email, :password)
  end
end
