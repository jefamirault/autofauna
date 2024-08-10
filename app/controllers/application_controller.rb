class ApplicationController < ActionController::Base


  private

  def authenticate
    redirect_to new_session_path, alert: 'You must be logged in order to do that.' unless user_signed_in?
  end

  def authorize
    redirect_to request.referer, alert: "You need permission for #{params[:controller].titleize}##{params[:action].titleize} in order to do that." unless authorized?(current_user)
  end
  def authorized?(user)
    user.admin?
  end

  def current_user
    Current.user ||= authenticate_user_from_session
  end
  helper_method :current_user

  def authenticate_user_from_session
    User.find_by(id: cookies.encrypted[:user_id])
  end

  def user_signed_in?
    current_user.present?
  end
  helper_method :user_signed_in?
  def login(user)
    Current.user = user
    reset_session
    cookies.encrypted[:user_id] = { value: user.id, expires: 6.months }
  end

  def logout
    Current.user = nil
    reset_session
    cookies.delete :user_id
    redirect_to sessions_new_path
  end
end
