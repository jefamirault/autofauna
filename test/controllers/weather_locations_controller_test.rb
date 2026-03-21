require "test_helper"

class WeatherLocationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user
    @location = @user.weather_locations.create!(
      latitude: 40.7128,
      longitude: -74.006,
      location_name: "New York",
      name: "Home",
      primary: true
    )
  end

  test "should create weather location" do
    assert_difference("WeatherLocation.count") do
      post weather_locations_path, params: {
        weather_location: { latitude: 34.0522, longitude: -118.2437, location_name: "Los Angeles" }
      }
    end
    assert_redirected_to weather_path
  end

  test "should update weather location name" do
    patch weather_location_path(@location), params: {
      weather_location: { name: "NYC" }
    }
    assert_redirected_to weather_path
    @location.reload
    assert_equal "NYC", @location.name
  end

  test "should destroy weather location" do
    assert_difference("WeatherLocation.count", -1) do
      delete weather_location_path(@location)
    end
    assert_redirected_to weather_path
  end

  test "should set primary" do
    second = @user.weather_locations.create!(latitude: 34.0522, longitude: -118.2437, location_name: "LA")
    patch set_primary_weather_location_path(second)
    assert_redirected_to weather_path
    second.reload
    @location.reload
    assert second.primary?
    assert_not @location.primary?
  end

  test "should not access other users locations" do
    other_user = users(:two)
    other_location = other_user.weather_locations.create!(latitude: 51.5, longitude: -0.1, location_name: "London", primary: true)
    delete weather_location_path(other_location)
    assert_redirected_to plants_path
  end

  test "destroying primary promotes next location" do
    second = @user.weather_locations.create!(latitude: 34.0522, longitude: -118.2437, location_name: "LA")
    delete weather_location_path(@location)
    second.reload
    assert second.primary?
  end
end
