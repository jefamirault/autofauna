class ApplicationController < ActionController::Base

  def authenticate
    redirect_to sessions_new_path unless cookies.encrypted[:logged_in]
  end
end
