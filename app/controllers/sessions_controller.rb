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
    logout
  end

  private

  def session_params
    params.require(:user).permit(:email, :password)
  end
end
