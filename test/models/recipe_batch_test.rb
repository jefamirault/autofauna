require "test_helper"

class RecipeBatchTest < ActiveSupport::TestCase
  setup do
    @project = Project.create!(name: "Batch Test", owner: users(:one))
    @recipe = Recipe.create!(name: "High N", project: @project)
    @batch = RecipeBatch.create!(
      project: @project,
      recipe: @recipe,
      tds: 400,
      volume: 10.0,
      volume_units: "gal",
      remaining_volume: 10.0,
      mixed_on: Date.current
    )
  end

  test "decrement_remaining reduces remaining volume" do
    @batch.decrement_remaining!(2.0, "gal")
    assert_in_delta 8.0, @batch.remaining_volume, 0.001
  end

  test "decrement_remaining clamps at zero" do
    @batch.decrement_remaining!(15.0, "gal")
    assert_equal 0.0, @batch.remaining_volume
  end

  test "increment_remaining adds to remaining volume" do
    @batch.update!(remaining_volume: 5.0)
    @batch.increment_remaining!(2.0, "gal")
    assert_in_delta 7.0, @batch.remaining_volume, 0.001
  end

  test "increment_remaining clamps at batch volume" do
    @batch.update!(remaining_volume: 9.5)
    @batch.increment_remaining!(5.0, "gal")
    assert_in_delta 10.0, @batch.remaining_volume, 0.001
  end

  test "decrement_remaining handles unit conversion (qt to gal)" do
    @batch.decrement_remaining!(4.0, "qt")
    # 4 qt = 1 gal
    assert_in_delta 9.0, @batch.remaining_volume, 0.01
  end

  test "remaining_percent is correct" do
    @batch.update!(remaining_volume: 5.0)
    assert_in_delta 50.0, @batch.remaining_percent, 0.01
  end

  test "remaining_percent is nil without remaining_volume" do
    @batch.update!(remaining_volume: nil)
    assert_nil @batch.remaining_percent
  end

  test "usage_per_day is zero with no waterings" do
    assert_in_delta 0.0, @batch.usage_per_day, 0.001
  end

  test "projected_runout is nil with no usage" do
    assert_nil @batch.projected_runout
  end

  test "projected_runout with usage" do
    plant = Plant.create!(name: "Pothos", project: @project, uid: 999)
    Watering.create!(plant: plant, recipe_batch: @batch, watered_at: Time.current, volume: 1.0, units: "gal")
    @batch.update!(remaining_volume: 5.0)

    # 1 gal used in 30 days = 1/30 gal/day
    # 5 gal remaining / (1/30 gal/day) = 150 days
    runout = @batch.projected_runout
    assert runout.present?
    assert runout > Date.current
  end

  test "replenishment_urgency is no_usage with no waterings" do
    assert_equal :no_usage, @batch.replenishment_urgency
  end
end
