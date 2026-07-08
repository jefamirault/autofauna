require "test_helper"

class PlantsHelperTest < ActionView::TestCase
  include PlantsHelper

  def build_plant(last_watered_days_ago:, min: nil, max: nil)
    Plant.new(
      date_last_watering: last_watered_days_ago&.days&.ago&.to_date,
      min_watering_freq: min,
      max_watering_freq: max
    )
  end

  test "gauge is nil without a schedule or last watering" do
    assert_nil watering_gauge_style(build_plant(last_watered_days_ago: 3))
    assert_nil watering_gauge_style(build_plant(last_watered_days_ago: nil, min: 5, max: 10))
    assert_nil watering_gauge_style(build_plant(last_watered_days_ago: 3, min: 5, max: nil))
    assert_nil watering_gauge_style(build_plant(last_watered_days_ago: 3, min: 5, max: 0))
  end

  test "gauge mid-window: track spans to max due date" do
    style = watering_gauge_style(build_plant(last_watered_days_ago: 5, min: 7, max: 10))
    assert_equal "--window-start: 70.0%; --window-end: 100.0%; --fill: 50.0%", style
  end

  test "gauge overdue: track extends to today so fill overshoots the window band" do
    # min 5 / max 10, watered 13 days ago -> total 13 days
    style = watering_gauge_style(build_plant(last_watered_days_ago: 13, min: 5, max: 10))
    assert_equal "--window-start: 38.5%; --window-end: 76.9%; --fill: 100.0%", style
  end

  test "gauge watered today: fill clamps to a visible sliver" do
    style = watering_gauge_style(build_plant(last_watered_days_ago: 0, min: 7, max: 10))
    assert_equal "--window-start: 70.0%; --window-end: 100.0%; --fill: 3.0%", style
  end

  test "gauge with min == max keeps a visible window sliver" do
    style = watering_gauge_style(build_plant(last_watered_days_ago: 2, min: 7, max: 7))
    assert_equal "--window-start: 94.0%; --window-end: 100.0%; --fill: 28.6%", style
  end
end
