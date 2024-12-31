require "application_system_test_case"

class SensorsTest < ApplicationSystemTestCase
  setup do
    @sensor = sensors(:one)
  end

  test "visiting the index" do
    visit sensors_url
    assert_selector "h1", text: "Sensors"
  end

  test "should create sensor" do
    visit sensors_url
    click_on "New sensor"

    fill_in "Description", with: @sensor.description
    fill_in "Location", with: @sensor.location
    fill_in "Name", with: @sensor.name
    fill_in "Project", with: @sensor.project_id
    fill_in "Zone", with: @sensor.zone_id
    click_on "Create Sensor"

    assert_text "Sensor was successfully created"
    click_on "Back"
  end

  test "should update Sensor" do
    visit sensor_url(@sensor)
    click_on "Edit this sensor", match: :first

    fill_in "Description", with: @sensor.description
    fill_in "Location", with: @sensor.location
    fill_in "Name", with: @sensor.name
    fill_in "Project", with: @sensor.project_id
    fill_in "Zone", with: @sensor.zone_id
    click_on "Update Sensor"

    assert_text "Sensor was successfully updated"
    click_on "Back"
  end

  test "should destroy Sensor" do
    visit sensor_url(@sensor)
    click_on "Destroy this sensor", match: :first

    assert_text "Sensor was successfully destroyed"
  end
end
