require "test_helper"

class FeedingInstructionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @tank = tanks(:one)
    sign_in @user
    @feeding_instruction = @tank.feeding_instructions.create!(
      food_name: "Hikari Cichlid Staple",
      amount: "10",
      unit: "pellets",
      frequency: "1x/day",
      notes: "1 x Oscar Cichlid"
    )
  end

  test "should get index" do
    get tank_feeding_instructions_url(@tank)
    assert_response :success
  end

  test "should get new" do
    get new_tank_feeding_instruction_url(@tank)
    assert_response :success
  end

  test "should create feeding instruction" do
    assert_difference("FeedingInstruction.count") do
      post tank_feeding_instructions_url(@tank), params: {
        feeding_instruction: { food_name: "TetraMin Flakes", amount: "5", unit: "flakes", frequency: "2x/day" }
      }
    end
    assert_redirected_to tank_url(@tank)
  end

  test "should not create feeding instruction without food name" do
    assert_no_difference("FeedingInstruction.count") do
      post tank_feeding_instructions_url(@tank), params: {
        feeding_instruction: { food_name: "", frequency: "1x/day" }
      }
    end
    assert_response :unprocessable_entity
  end

  test "should get edit" do
    get edit_tank_feeding_instruction_url(@tank, @feeding_instruction)
    assert_response :success
  end

  test "should update feeding instruction" do
    patch tank_feeding_instruction_url(@tank, @feeding_instruction), params: {
      feeding_instruction: { frequency: "2x/day" }
    }
    assert_redirected_to tank_url(@tank)
  end

  test "should destroy feeding instruction" do
    assert_difference("FeedingInstruction.count", -1) do
      delete tank_feeding_instruction_url(@tank, @feeding_instruction)
    end
    assert_redirected_to tank_url(@tank)
  end

  test "should not access feeding instruction from another project" do
    sign_in users(:two)
    get new_tank_feeding_instruction_url(@tank)
    assert_redirected_to plants_url
  end
end
