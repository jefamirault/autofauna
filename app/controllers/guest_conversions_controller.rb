class GuestConversionsController < ApplicationController
  before_action :authenticate
  before_action :require_guest

  def new
  end

  def create
    existing_user = User.find_by(email: params[:email])
    if existing_user
      if existing_user.authenticate(params[:password])
        existing_user.merge_guest!(current_user)
        login existing_user
        auto_select_project(existing_user)
        redirect_to plants_path, notice: t("guest.conversion_success")
      else
        flash.now[:alert] = t("guest.invalid_password")
        render :new, status: :unprocessable_entity
      end
    else
      current_user.convert_from_guest!(
        email: params[:email],
        password: params[:password],
        password_confirmation: params[:password_confirmation]
      )
      redirect_to plants_path, notice: t("guest.conversion_success")
    end
  rescue ActiveRecord::RecordInvalid
    flash.now[:alert] = current_user.errors.full_messages.join(", ")
    render :new, status: :unprocessable_entity
  end

  private

  def require_guest
    redirect_to plants_path unless current_user&.guest?
  end
end
