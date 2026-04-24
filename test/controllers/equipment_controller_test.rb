require "test_helper"

class EquipmentControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @tank = tanks(:one)
    sign_in @user
    @equipment_item = @tank.equipment.create!(
      name: "Canister Filter",
      maintenance_instructions: "Clean media monthly",
      maintenance_interval_days: 30
    )
  end

  test "should get index" do
    get tank_equipment_index_url(@tank)
    assert_response :success
  end

  test "should get new" do
    get new_tank_equipment_url(@tank)
    assert_response :success
  end

  test "should create equipment" do
    assert_difference("Equipment.count") do
      post tank_equipment_index_url(@tank), params: {
        equipment: { name: "LED Light", maintenance_instructions: "Replace bulb yearly", maintenance_interval_days: 365 }
      }
    end
    assert_redirected_to tank_url(@tank)
  end

  test "should not create equipment without name" do
    assert_no_difference("Equipment.count") do
      post tank_equipment_index_url(@tank), params: {
        equipment: { name: "" }
      }
    end
    assert_response :unprocessable_entity
  end

  test "should show equipment" do
    get tank_equipment_url(@tank, @equipment_item)
    assert_response :success
  end

  test "should get edit" do
    get edit_tank_equipment_url(@tank, @equipment_item)
    assert_response :success
  end

  test "should update equipment" do
    patch tank_equipment_url(@tank, @equipment_item), params: {
      equipment: { maintenance_interval_days: 14 }
    }
    assert_redirected_to tank_equipment_url(@tank, @equipment_item)
  end

  test "should destroy equipment" do
    assert_difference("Equipment.count", -1) do
      delete tank_equipment_url(@tank, @equipment_item)
    end
    assert_redirected_to tank_url(@tank)
  end

  test "should not access equipment from another project" do
    sign_in users(:two)
    get new_tank_equipment_url(@tank)
    assert_redirected_to plants_url
  end
end
