require "application_system_test_case"

class WateringsTest < ApplicationSystemTestCase
  setup do
    @watering = waterings(:one)
  end

  test "visiting the index" do
    visit waterings_url
    assert_selector "h1", text: "Waterings"
  end

  test "should create watering" do
    visit waterings_url
    click_on "New watering"

    fill_in "Date", with: @watering.date
    fill_in "Notes", with: @watering.notes
    fill_in "Plant", with: @watering.plant_id
    click_on "Create Watering"

    assert_text "Watering was successfully created"
    click_on "Back"
  end

  test "should update Watering" do
    visit watering_url(@watering)
    click_on "Edit this watering", match: :first

    fill_in "Date", with: @watering.date
    fill_in "Notes", with: @watering.notes
    fill_in "Plant", with: @watering.plant_id
    click_on "Update Watering"

    assert_text "Watering was successfully updated"
    click_on "Back"
  end

  test "should destroy Watering" do
    visit watering_url(@watering)
    click_on "Destroy this watering", match: :first

    assert_text "Watering was successfully destroyed"
  end
end
