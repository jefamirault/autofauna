require "test_helper"

class WeatherControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user
  end

  test "should get index" do
    get weather_path
    assert_response :success
  end

  test "should redirect to login when not authenticated" do
    delete session_path
    get weather_path
    assert_redirected_to new_session_path
  end

  test "should redirect on lookup with invalid zip" do
    post weather_lookup_path, params: { zip: "zzzzz" }
    assert_redirected_to weather_path
    assert_match "Could not find location", flash[:alert]
  end

  test "should show location form when no locations saved" do
    get weather_path
    assert_response :success
    assert_select ".settings-card h2", "Location"
  end

  test "should show location management when locations exist" do
    @user.weather_locations.create!(latitude: 40.7128, longitude: -74.006, location_name: "New York", primary: true)
    get weather_path
    assert_response :success
    assert_select ".settings-card h2", "Locations"
  end
end
