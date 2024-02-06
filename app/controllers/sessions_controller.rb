class SessionsController < ApplicationController
  def new

  end

  def create
    if params[:password] == ENV['ADMIN_PASSWORD']
      session[:logged_in] = true
      redirect_to plants_path
    end
  end

  def destroy
    session[:logged_in] = false
    redirect_to sessions_new_path
  end
end
