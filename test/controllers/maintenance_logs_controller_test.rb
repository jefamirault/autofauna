require "test_helper"

class MaintenanceLogsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @tank = tanks(:one)
    sign_in @user
    @equipment_item = @tank.equipment.create!(
      name: "Canister Filter",
      maintenance_interval_days: 30
    )
    @maintenance_log = @equipment_item.maintenance_logs.create!(
      performed_at: 1.week.ago,
      notes: "Cleaned filter media"
    )
  end

  test "should get new" do
    get new_tank_equipment_maintenance_log_url(@tank, @equipment_item)
    assert_response :success
  end

  test "should create maintenance log" do
    assert_difference("MaintenanceLog.count") do
      post tank_equipment_maintenance_logs_url(@tank, @equipment_item), params: {
        maintenance_log: { performed_at: Time.current, notes: "Replaced filter sponge" }
      }
    end
    assert_redirected_to tank_equipment_url(@tank, @equipment_item)
  end

  test "should get edit" do
    get edit_tank_equipment_maintenance_log_url(@tank, @equipment_item, @maintenance_log)
    assert_response :success
  end

  test "should update maintenance log" do
    patch tank_equipment_maintenance_log_url(@tank, @equipment_item, @maintenance_log), params: {
      maintenance_log: { notes: "Updated note" }
    }
    assert_redirected_to tank_equipment_url(@tank, @equipment_item)
  end

  test "should destroy maintenance log" do
    assert_difference("MaintenanceLog.count", -1) do
      delete tank_equipment_maintenance_log_url(@tank, @equipment_item, @maintenance_log)
    end
    assert_redirected_to tank_equipment_url(@tank, @equipment_item)
  end

  test "should not access maintenance log from another project" do
    sign_in users(:two)
    get new_tank_equipment_maintenance_log_url(@tank, @equipment_item)
    assert_redirected_to plants_url
  end
end
