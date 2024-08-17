class SettingsController < ApplicationController
  def index

  end

  def english
    cookies[:locale] = :en
    redirect_to root_path
  end
  def spanish
    cookies[:locale] = :es
    redirect_to root_path
  end
end