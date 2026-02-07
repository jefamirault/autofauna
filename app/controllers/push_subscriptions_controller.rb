class PushSubscriptionsController < ApplicationController
  before_action :authenticate

  def create
    subscription = current_user.push_subscriptions.find_or_initialize_by(
      endpoint: params[:endpoint]
    )
    subscription.p256dh_key = params[:p256dh_key]
    subscription.auth_key = params[:auth_key]
    subscription.user_agent = request.user_agent

    if subscription.save
      head :created
    else
      head :unprocessable_entity
    end
  end

  def destroy
    subscription = current_user.push_subscriptions.find_by(endpoint: params[:endpoint])
    subscription&.destroy
    head :ok
  end
end
