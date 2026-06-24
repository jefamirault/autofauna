require "net/http"

class GoogleAuthController < ApplicationController
  skip_before_action :require_onboarding
  skip_forgery_protection only: :callback

  def callback
    payload = verify_google_token(params[:credential])

    unless payload
      redirect_to new_session_path, alert: t("google_auth.invalid_token")
      return
    end

    google_uid = payload["sub"]
    email = payload["email"]
    avatar_url = payload["picture"]

    # Case 1: Existing user with matching google_uid
    user = User.find_by(google_uid: google_uid)
    if user
      was_guest = current_user&.guest?
      user.merge_guest!(current_user) if was_guest
      login user
      auto_select_project(user)
      redirect_to plants_path, notice: t(was_guest ? "guest.conversion_success" : "account.sign_in_success")
      return
    end

    # Case 3: Current user is a guest -> convert or merge
    if current_user&.guest?
      existing_user = User.find_by(email: email)
      if existing_user
        existing_user.update!(google_uid: google_uid, avatar_url: avatar_url)
        existing_user.merge_guest!(current_user)
        login existing_user
        auto_select_project(existing_user)
      else
        current_user.convert_from_guest_google!(email: email, google_uid: google_uid, avatar_url: avatar_url)
      end
      redirect_to plants_path, notice: t("guest.conversion_success")
      return
    end

    # Case 2: Existing user with matching email -> link Google account
    user = User.find_by(email: email)
    if user
      user.update!(google_uid: google_uid, avatar_url: avatar_url)
      login user
      auto_select_project(user)
      redirect_to plants_path, notice: t("account.sign_in_success")
      return
    end

    # Case 4: New user
    user = User.create!(
      email: email,
      google_uid: google_uid,
      avatar_url: avatar_url,
      password: SecureRandom.hex(32)
    )
    login user
    set_current_project user.projects.first
    redirect_to plants_path, notice: t("account.sign_in_success")
  end

  private

  def verify_google_token(token)
    uri = URI("https://oauth2.googleapis.com/tokeninfo?id_token=#{token}")
    response = Net::HTTP.get_response(uri)
    return nil unless response.is_a?(Net::HTTPSuccess)

    payload = JSON.parse(response.body)
    client_id = Rails.application.credentials.dig(:google, :client_id)

    return nil unless payload["aud"] == client_id
    return nil unless payload["email_verified"] == "true"

    payload
  rescue JSON::ParserError
    nil
  end

end
