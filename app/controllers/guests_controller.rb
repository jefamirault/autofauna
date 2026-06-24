class GuestsController < ApplicationController
  skip_before_action :require_onboarding

  def create
    user = User.create!(guest: true, password: SecureRandom.hex(32))
    login user
    set_current_project user.projects.first
    redirect_to plants_path
  end
end
