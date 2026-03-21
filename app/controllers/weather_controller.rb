class WeatherController < ApplicationController
  before_action :authenticate

  def index
    @weather_locations = current_user.weather_locations.order(primary: :desc, created_at: :asc)
    @primary_location = @weather_locations.find(&:primary?) || @weather_locations.first

    if @primary_location
      @weather = WeatherService.fetch(lat: @primary_location.latitude, lon: @primary_location.longitude)
      if @weather
        @weather[:location_name] ||= @primary_location.display_name
      else
        flash.now[:alert] = "Could not fetch weather data. Please try again."
      end
    end
  end

  def lookup
    zip = params[:zip].to_s.strip
    geo = WeatherService.geocode_zip(zip)
    if geo
      is_first = current_user.weather_locations.none?
      current_user.weather_locations.create!(
        latitude: geo[:lat],
        longitude: geo[:lon],
        zip: zip,
        location_name: geo[:name],
        primary: is_first
      )
      redirect_to weather_path
    else
      redirect_to weather_path, alert: "Could not find location for zip code \"#{zip}\"."
    end
  end
end
