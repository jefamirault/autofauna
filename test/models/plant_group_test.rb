require "test_helper"

class PlantGroupTest < ActiveSupport::TestCase
  setup do
    @group = plant_groups(:one)
  end

  test "has many plants through memberships" do
    assert_includes @group.plants, plants(:one)
    assert_includes @group.plants, plants(:two)
  end

  test "name is required" do
    group = PlantGroup.new(project: projects(:one))
    assert_not group.valid?
    assert_includes group.errors[:name], "can't be blank"
  end

  test "hex_color falls back to default when blank" do
    group = PlantGroup.new(color: nil)
    assert_equal "#0E487B", group.hex_color
  end

  test "water_all! creates one watering per non-archived member" do
    members = @group.plants.where(archived: false).to_a
    assert members.size >= 2

    watered = nil
    assert_difference("Watering.count", members.size) do
      watered = @group.water_all!
    end

    assert_equal members.size, watered.size
    assert watered.all? { |w| w.is_a?(Watering) }
    assert_equal members.map(&:id).sort, watered.map(&:plant_id).sort
  end

  test "water_all! skips archived members" do
    plants(:two).update!(archived: true)
    members = @group.plants.where(archived: false).to_a

    assert_difference("Watering.count", members.size) do
      @group.water_all!
    end
  end

  test "apply_schedule_to_members! pushes the group schedule onto members" do
    @group.update!(min_watering_freq: 3, max_watering_freq: 5)
    @group.apply_schedule_to_members!

    @group.plants.each do |plant|
      plant.reload
      assert_equal 3, plant.min_watering_freq
      assert_equal 5, plant.max_watering_freq
    end
  end

  test "apply_schedule_to_members! is a no-op when no schedule set" do
    @group.update!(min_watering_freq: nil, max_watering_freq: nil)
    assert_nil plants(:one).min_watering_freq # fixture has no schedule
    @group.apply_schedule_to_members!
    assert_nil plants(:one).reload.min_watering_freq, "schedule should be unchanged"
  end

  test "groups are scoped to a project" do
    assert_equal projects(:one), @group.project
    assert_not_includes projects(:one).plant_groups, plant_groups(:group_p2)
  end
end
