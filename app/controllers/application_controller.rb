class ApplicationController < ActionController::Base

  def authenticate
    redirect_to sessions_new_path unless session[:logged_in]
  end
end
