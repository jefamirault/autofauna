class RegistrationsController < ApplicationController
  def new
    @user = User.new
  end

  def create
    @user = User.new registration_params
    if @user.save
      login @user
      set_current_project @user.projects.first
      redirect_to plants_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def registration_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end
end