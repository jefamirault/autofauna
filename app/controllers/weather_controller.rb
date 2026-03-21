class WeatherController < ApplicationController
  before_action :authenticate

  def index
    if params[:lat].present? && params[:lon].present?
      lat = params[:lat].to_f
      lon = params[:lon].to_f
      cookies[:weather_lat] = { value: lat.to_s, expires: 1.year }
      cookies[:weather_lon] = { value: lon.to_s, expires: 1.year }
      cookies.delete(:weather_zip)
      @weather = WeatherService.fetch(lat: lat, lon: lon)
    elsif cookies[:weather_zip].present?
      @zip = cookies[:weather_zip]
      geo = WeatherService.geocode_zip(@zip)
      if geo
        @weather = WeatherService.fetch(lat: geo[:lat], lon: geo[:lon])
        @weather[:location_name] = geo[:name] if @weather
      end
    elsif cookies[:weather_lat].present? && cookies[:weather_lon].present?
      @weather = WeatherService.fetch(lat: cookies[:weather_lat].to_f, lon: cookies[:weather_lon].to_f)
    end

    flash.now[:alert] = "Could not fetch weather data. Please try again." if location_provided? && @weather.nil?
  end

  def lookup
    zip = params[:zip].to_s.strip
    geo = WeatherService.geocode_zip(zip)
    if geo
      cookies[:weather_zip] = { value: zip, expires: 1.year }
      cookies[:weather_lat] = { value: geo[:lat].to_s, expires: 1.year }
      cookies[:weather_lon] = { value: geo[:lon].to_s, expires: 1.year }
      redirect_to weather_path
    else
      redirect_to weather_path, alert: "Could not find location for zip code \"#{zip}\"."
    end
  end

  private

  def location_provided?
    params[:lat].present? || cookies[:weather_zip].present? || cookies[:weather_lat].present?
  end
end
