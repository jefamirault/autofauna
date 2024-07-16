class SessionsController < ApplicationController
  def new

  end

  def create
    if params[:password] == ENV['ADMIN_PASSWORD']
      cookies.encrypted[:logged_in] = { value: true, expires: 6.months }
      redirect_to plants_path
    end
  end

  def destroy
    cookies.delete :logged_in
    redirect_to sessions_new_path
  end
end
