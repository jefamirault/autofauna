class GuestConversionsController < ApplicationController
  before_action :authenticate
  before_action :require_guest

  def new
  end

  def create
    current_user.convert_from_guest!(
      email: params[:email],
      password: params[:password],
      password_confirmation: params[:password_confirmation]
    )
    redirect_to plants_path, notice: t("guest.conversion_success")
  rescue ActiveRecord::RecordInvalid
    flash.now[:alert] = current_user.errors.full_messages.join(", ")
    render :new, status: :unprocessable_entity
  end

  private

  def require_guest
    redirect_to plants_path unless current_user&.guest?
  end
end
