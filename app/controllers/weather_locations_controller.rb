class WeatherLocationsController < ApplicationController
  before_action :authenticate
  before_action :set_weather_location, only: [:update, :destroy, :set_primary]

  def create
    @weather_location = current_user.weather_locations.new(weather_location_params)

    # First location is automatically primary
    @weather_location.primary = true if current_user.weather_locations.none?

    # Resolve location name from geocoding if we have a zip
    if @weather_location.zip.present? && @weather_location.location_name.blank?
      geo = WeatherService.geocode_zip(@weather_location.zip)
      if geo
        @weather_location.latitude = geo[:lat]
        @weather_location.longitude = geo[:lon]
        @weather_location.location_name = geo[:name]
      end
    end

    if @weather_location.save
      redirect_to weather_path
    else
      redirect_to weather_path, alert: "Could not save location."
    end
  end

  def update
    if @weather_location.update(weather_location_params.slice(:name))
      redirect_to weather_path
    else
      redirect_to weather_path, alert: "Could not update location."
    end
  end

  def destroy
    was_primary = @weather_location.primary?
    @weather_location.destroy

    # If we deleted the primary, promote the next one
    if was_primary
      next_location = current_user.weather_locations.first
      next_location&.update!(primary: true)
    end

    redirect_to weather_path
  end

  def set_primary
    @weather_location.make_primary!
    redirect_to weather_path
  end

  private

  def set_weather_location
    @weather_location = current_user.weather_locations.find(params[:id])
  end

  def weather_location_params
    params.require(:weather_location).permit(:name, :latitude, :longitude, :zip, :location_name)
  end
end
