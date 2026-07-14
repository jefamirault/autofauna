class GuestsController < ApplicationController
  skip_before_action :require_onboarding

  rate_limit to: 10, within: 1.hour, only: :create,
             store: RateLimiting::STORE, with: -> { rate_limit_exceeded }

  def create
    user = User.create!(guest: true, password: SecureRandom.hex(32))
    login user
    set_current_project user.projects.first
    redirect_to plants_path
  end
end
