require "application_system_test_case"

class SensorTypesTest < ApplicationSystemTestCase
  setup do
    @sensor_type = sensor_types(:one)
  end

  test "visiting the index" do
    visit sensor_types_url
    assert_selector "h1", text: "Sensor types"
  end

  test "should create sensor type" do
    visit sensor_types_url
    click_on "New sensor type"

    fill_in "Accuracy humidity", with: @sensor_type.accuracy_humidity
    fill_in "Accuracy temp", with: @sensor_type.accuracy_temp
    fill_in "Max humidity", with: @sensor_type.max_humidity
    fill_in "Max temp", with: @sensor_type.max_temp
    fill_in "Min humidity", with: @sensor_type.min_humidity
    fill_in "Min temp", with: @sensor_type.min_temp
    fill_in "Name", with: @sensor_type.name
    fill_in "Resolution humidity", with: @sensor_type.resolution_humidity
    fill_in "Resolution temp", with: @sensor_type.resolution_temp
    click_on "Create Sensor type"

    assert_text "Sensor type was successfully created"
    click_on "Back"
  end

  test "should update Sensor type" do
    visit sensor_type_url(@sensor_type)
    click_on "Edit this sensor type", match: :first

    fill_in "Accuracy humidity", with: @sensor_type.accuracy_humidity
    fill_in "Accuracy temp", with: @sensor_type.accuracy_temp
    fill_in "Max humidity", with: @sensor_type.max_humidity
    fill_in "Max temp", with: @sensor_type.max_temp
    fill_in "Min humidity", with: @sensor_type.min_humidity
    fill_in "Min temp", with: @sensor_type.min_temp
    fill_in "Name", with: @sensor_type.name
    fill_in "Resolution humidity", with: @sensor_type.resolution_humidity
    fill_in "Resolution temp", with: @sensor_type.resolution_temp
    click_on "Update Sensor type"

    assert_text "Sensor type was successfully updated"
    click_on "Back"
  end

  test "should destroy Sensor type" do
    visit sensor_type_url(@sensor_type)
    click_on "Destroy this sensor type", match: :first

    assert_text "Sensor type was successfully destroyed"
  end
end
