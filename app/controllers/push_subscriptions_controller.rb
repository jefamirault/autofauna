class PushSubscriptionsController < ApplicationController
  skip_before_action :require_onboarding
  before_action :authenticate

  def create
    subscription = current_user.push_subscriptions.find_or_initialize_by(
      endpoint: params[:endpoint]
    )
    subscription.p256dh_key = params[:p256dh_key]
    subscription.auth_key = params[:auth_key]
    subscription.user_agent = request.user_agent
    subscription.enabled = true

    if subscription.save
      head :created
    else
      head :unprocessable_entity
    end
  end

  def toggle
    subscription = current_user.push_subscriptions.find(params[:id])
    subscription.update!(enabled: !subscription.enabled)

    respond_to do |format|
      format.json { render json: { enabled: subscription.enabled }, status: :ok }
      format.html do
        status = subscription.enabled? ? "enabled" : "disabled"
        redirect_to settings_path, notice: "Device #{status}"
      end
    end
  end

  def destroy
    subscription = if params[:id].to_s.match?(/\A\d+\z/)
      current_user.push_subscriptions.find_by(id: params[:id])
    else
      current_user.push_subscriptions.find_by(endpoint: params[:endpoint] || params[:id])
    end

    subscription&.destroy

    if request.format.html? || request.headers["Turbo-Frame"].present?
      redirect_to settings_path, notice: "Device removed"
    else
      head :ok
    end
  end
end
