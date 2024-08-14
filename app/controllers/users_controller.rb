class UsersController < ApplicationController

  before_action :authorize_admin

  def index
    @users = User.all
  end
end