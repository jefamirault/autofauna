class SessionsController < ApplicationController
  def new
    @user = User.new
  end

  def create
    @user = User.authenticate_by(session_params)
    if @user.present?
      login @user
      auto_select_project_for(@user)
      redirect_to plants_path, notice: t('account.sign_in_success')
    else
      flash[:alert] = t('errors.invalid_email_or_password')
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    logout
  end

  private

  def auto_select_project_for(user)
    return if user.advanced_mode?

    # Auto-select if user has exactly one owned project
    if user.projects.count == 1
      set_current_project(user.projects.first)
    # Or if they're a collaborator on exactly one project total
    elsif user.projects.empty?
      collaborations = Collaboration.where(user: user)
      if collaborations.count == 1
        set_current_project(collaborations.first.project)
      end
    end
  end

  def session_params
    params.require(:user).permit(:email, :password)
  end
end
