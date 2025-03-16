require "application_system_test_case"

class TdsReadingsTest < ApplicationSystemTestCase
  setup do
    @tds_reading = tds_readings(:one)
  end

  test "visiting the index" do
    visit tds_readings_url
    assert_selector "h1", text: "Tds readings"
  end

  test "should create tds reading" do
    visit tds_readings_url
    click_on "New tds reading"

    fill_in "Datetime", with: @tds_reading.datetime
    fill_in "Sensor", with: @tds_reading.sensor_id
    fill_in "Tds", with: @tds_reading.tds
    fill_in "Zone", with: @tds_reading.zone_id
    click_on "Create Tds reading"

    assert_text "Tds reading was successfully created"
    click_on "Back"
  end

  test "should update Tds reading" do
    visit tds_reading_url(@tds_reading)
    click_on "Edit this tds reading", match: :first

    fill_in "Datetime", with: @tds_reading.datetime.to_s
    fill_in "Sensor", with: @tds_reading.sensor_id
    fill_in "Tds", with: @tds_reading.tds
    fill_in "Zone", with: @tds_reading.zone_id
    click_on "Update Tds reading"

    assert_text "Tds reading was successfully updated"
    click_on "Back"
  end

  test "should destroy Tds reading" do
    visit tds_reading_url(@tds_reading)
    click_on "Destroy this tds reading", match: :first

    assert_text "Tds reading was successfully destroyed"
  end
end
