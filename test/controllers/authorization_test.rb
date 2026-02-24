require "test_helper"

# Tests that resources are scoped to the current project and cannot be
# accessed by users belonging to a different project.
#
# Setup: users(:two) owns projects(:two). All resources under test (:one, :two
# fixture entries) belong to projects(:one), which is owned by users(:one).
# After signing in as users(:two), the auto_select_project logic sets
# current_project to projects(:two). Attempting to find a resource that
# belongs to projects(:one) will raise ActiveRecord::RecordNotFound
# (because the scope is current_project.<association>.find(id)), which
# ApplicationController rescues and redirects to plants_path.
class AuthorizationTest < ActionDispatch::IntegrationTest
  setup do
    @user_two = users(:two)
    sign_in @user_two
  end

  # Plants

  test "user cannot show another project's plant" do
    get plant_url(plants(:one))
    assert_redirected_to plants_path
  end

  test "user cannot edit another project's plant" do
    get edit_plant_url(plants(:one))
    assert_redirected_to plants_path
  end

  test "user cannot update another project's plant" do
    patch plant_url(plants(:one)), params: { plant: { name: "Hacked" } }
    assert_redirected_to plants_path
  end

  test "user cannot destroy another project's plant" do
    delete plant_url(plants(:one))
    assert_redirected_to plants_path
  end

  # Waterings

  test "user cannot show another project's watering" do
    get watering_url(waterings(:one))
    assert_redirected_to plants_path
  end

  test "user cannot edit another project's watering" do
    get edit_watering_url(waterings(:one))
    assert_redirected_to plants_path
  end

  test "user cannot update another project's watering" do
    patch watering_url(waterings(:one)), params: { watering: { notes: "Hacked" } }
    assert_redirected_to plants_path
  end

  test "user cannot destroy another project's watering" do
    delete watering_url(waterings(:one))
    assert_redirected_to plants_path
  end

  # Tanks

  test "user cannot show another project's tank" do
    get tank_url(tanks(:one))
    assert_redirected_to plants_path
  end

  test "user cannot edit another project's tank" do
    get edit_tank_url(tanks(:one))
    assert_redirected_to plants_path
  end

  test "user cannot update another project's tank" do
    patch tank_url(tanks(:one)), params: { tank: { name: "Hacked" } }
    assert_redirected_to plants_path
  end

  test "user cannot destroy another project's tank" do
    delete tank_url(tanks(:one))
    assert_redirected_to plants_path
  end

  # Locations

  test "user cannot show another project's location" do
    get location_url(locations(:one))
    assert_redirected_to plants_path
  end

  test "user cannot edit another project's location" do
    get edit_location_url(locations(:one))
    assert_redirected_to plants_path
  end

  test "user cannot update another project's location" do
    patch location_url(locations(:one)), params: { location: { name: "Hacked" } }
    assert_redirected_to plants_path
  end

  test "user cannot destroy another project's location" do
    delete location_url(locations(:one))
    assert_redirected_to plants_path
  end

  # Zones

  test "user cannot show another project's zone" do
    get zone_url(zones(:one))
    assert_redirected_to plants_path
  end

  test "user cannot edit another project's zone" do
    get edit_zone_url(zones(:one))
    assert_redirected_to plants_path
  end

  test "user cannot update another project's zone" do
    patch zone_url(zones(:one)), params: { zone: { name: "Hacked" } }
    assert_redirected_to plants_path
  end

  test "user cannot destroy another project's zone" do
    delete zone_url(zones(:one))
    assert_redirected_to plants_path
  end

  # Sensors

  test "user cannot show another project's sensor" do
    get sensor_url(sensors(:one))
    assert_redirected_to plants_path
  end

  test "user cannot edit another project's sensor" do
    get edit_sensor_url(sensors(:one))
    assert_redirected_to plants_path
  end

  test "user cannot update another project's sensor" do
    patch sensor_url(sensors(:one)), params: { sensor: { name: "Hacked" } }
    assert_redirected_to plants_path
  end

  test "user cannot destroy another project's sensor" do
    delete sensor_url(sensors(:one))
    assert_redirected_to plants_path
  end

  # Sensor Types

  test "user cannot show another project's sensor type" do
    get sensor_type_url(sensor_types(:one))
    assert_redirected_to plants_path
  end

  test "user cannot edit another project's sensor type" do
    get edit_sensor_type_url(sensor_types(:one))
    assert_redirected_to plants_path
  end

  test "user cannot update another project's sensor type" do
    patch sensor_type_url(sensor_types(:one)), params: { sensor_type: { name: "Hacked" } }
    assert_redirected_to plants_path
  end

  test "user cannot destroy another project's sensor type" do
    delete sensor_type_url(sensor_types(:one))
    assert_redirected_to plants_path
  end
end
