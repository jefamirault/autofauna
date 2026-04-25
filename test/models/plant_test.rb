require "test_helper"

class PlantTest < ActiveSupport::TestCase
  test "when watering a plant, update watering dates based on freq" do
    project = Project.create(name: "A Project", owner: users(:one))
    plant = Plant.create!(name: "A Plant", min_watering_freq: 5, max_watering_freq: 7, project: project, uid: 100)
    watering = Watering.create!(plant: plant, watered_at: Time.zone.now)
    plant.reload
    plant.update_watering_dates
    plant.reload
    assert_equal watering.watered_at.to_date + 5.days, plant.date_min_watering
  end

  # ─── update_watering_dates ──────────────────────────────────────────────────

  test "update_watering_dates with a single watering sets all date fields" do
    project = Project.create!(name: "Test Project", owner: users(:one))
    plant = Plant.create!(name: "Single Watering Plant", min_watering_freq: 7, max_watering_freq: 14, project: project, uid: 101)
    watered_on = Date.new(2026, 1, 10)
    Watering.create!(plant: plant, watered_at: watered_on.to_time)
    plant.reload
    plant.update_watering_dates
    plant.reload

    assert_equal watered_on, plant.date_last_watering
    assert_equal watered_on + 7.days,  plant.date_min_watering
    assert_equal watered_on + 14.days, plant.date_max_watering
    expected_sort = watered_on + ((14 + 7) / 2).days
    assert_equal expected_sort, plant.date_sort_watering
  end

  test "update_watering_dates with multiple waterings uses the latest" do
    project = Project.create!(name: "Test Project", owner: users(:one))
    plant = Plant.create!(name: "Multi Watering Plant", min_watering_freq: 3, max_watering_freq: 5, project: project, uid: 102)
    early_date = Date.new(2026, 1, 1)
    late_date  = Date.new(2026, 1, 20)
    Watering.create!(plant: plant, watered_at: early_date.to_time)
    Watering.create!(plant: plant, watered_at: late_date.to_time)
    plant.reload
    plant.update_watering_dates
    plant.reload

    assert_equal late_date, plant.date_last_watering
    assert_equal late_date + 3.days, plant.date_min_watering
    assert_equal late_date + 5.days, plant.date_max_watering
  end

  test "update_watering_dates with no waterings sets all dates to nil" do
    project = Project.create!(name: "Test Project", owner: users(:one))
    plant = Plant.create!(name: "Unwatered Plant", min_watering_freq: 7, max_watering_freq: 14, project: project, uid: 103)
    plant.update_watering_dates
    plant.reload

    assert_nil plant.date_last_watering
    assert_nil plant.date_min_watering
    assert_nil plant.date_max_watering
    assert_nil plant.date_sort_watering
  end

  test "update_watering_dates without schedule leaves min/max/sort nil even with waterings" do
    project = Project.create!(name: "Test Project", owner: users(:one))
    plant = Plant.create!(name: "No Schedule Plant", project: project, uid: 104)
    Watering.create!(plant: plant, watered_at: Date.new(2026, 1, 15).to_time)
    plant.reload
    plant.update_watering_dates
    plant.reload

    assert_equal Date.new(2026, 1, 15), plant.date_last_watering
    assert_nil plant.date_min_watering
    assert_nil plant.date_max_watering
    assert_nil plant.date_sort_watering
  end

  test "update_watering_dates without min freq leaves date_min_watering nil" do
    project = Project.create!(name: "Test Project", owner: users(:one))
    plant = Plant.create!(name: "Max Only Plant", max_watering_freq: 10, project: project, uid: 105)
    watered_on = Date.new(2026, 1, 10)
    Watering.create!(plant: plant, watered_at: watered_on.to_time)
    plant.reload
    plant.update_watering_dates
    plant.reload

    assert_equal watered_on, plant.date_last_watering
    assert_nil plant.date_min_watering
    assert_equal watered_on + 10.days, plant.date_max_watering
    assert_nil plant.date_sort_watering
  end

  # ─── watering_urgency ───────────────────────────────────────────────────────

  test "watering_urgency returns :scheduled when no schedule" do
    project = Project.create!(name: "Test Project", owner: users(:one))
    plant = Plant.create!(name: "No Schedule", project: project, uid: 110)
    assert_equal :scheduled, plant.watering_urgency
  end

  test "watering_urgency returns :scheduled when not yet watered" do
    project = Project.create!(name: "Test Project", owner: users(:one))
    plant = Plant.create!(name: "Never Watered", min_watering_freq: 7, max_watering_freq: 14, project: project, uid: 111)
    # date_last_watering is nil so urgency should be :scheduled
    assert_equal :scheduled, plant.watering_urgency
  end

  test "watering_urgency returns :needs_water when overdue" do
    project = Project.create!(name: "Test Project", owner: users(:one))
    plant = Plant.create!(name: "Overdue Plant", min_watering_freq: 7, max_watering_freq: 14, project: project, uid: 112)
    # Set last watering to 20 days ago — overdue past max freq
    plant.update!(date_last_watering: 20.days.ago.to_date)
    assert_equal :needs_water, plant.watering_urgency
  end

  test "watering_urgency returns :needs_water when due today" do
    project = Project.create!(name: "Test Project", owner: users(:one))
    plant = Plant.create!(name: "Due Today Plant", min_watering_freq: 7, max_watering_freq: 14, project: project, uid: 113)
    # Last watered exactly max_watering_freq days ago
    plant.update!(date_last_watering: 14.days.ago.to_date)
    assert_equal :needs_water, plant.watering_urgency
  end

  test "watering_urgency returns :scheduled when not yet due" do
    project = Project.create!(name: "Test Project", owner: users(:one))
    plant = Plant.create!(name: "Upcoming Plant", min_watering_freq: 7, max_watering_freq: 14, project: project, uid: 114)
    # Last watered 5 days ago — within schedule
    plant.update!(date_last_watering: 5.days.ago.to_date)
    assert_equal :scheduled, plant.watering_urgency
  end

  # ─── time_until_watering ────────────────────────────────────────────────────

  test "time_until_watering returns nil when no date_min_watering" do
    project = Project.create!(name: "Test Project", owner: users(:one))
    plant = Plant.create!(name: "No Min Plant", project: project, uid: 120)
    assert_nil plant.time_until_watering
  end

  test "time_until_watering returns positive days when watering is upcoming" do
    project = Project.create!(name: "Test Project", owner: users(:one))
    plant = Plant.create!(name: "Future Watering", min_watering_freq: 10, max_watering_freq: 14, project: project, uid: 121)
    plant.update!(date_last_watering: 3.days.ago.to_date, date_min_watering: 7.days.from_now.to_date)
    assert plant.time_until_watering > 0
  end

  test "time_until_watering returns zero when due today" do
    project = Project.create!(name: "Test Project", owner: users(:one))
    plant = Plant.create!(name: "Due Today", min_watering_freq: 7, max_watering_freq: 14, project: project, uid: 122)
    plant.update!(date_last_watering: 7.days.ago.to_date, date_min_watering: Date.current)
    assert_equal 0, plant.time_until_watering
  end

  test "time_until_watering returns negative days when overdue" do
    project = Project.create!(name: "Test Project", owner: users(:one))
    plant = Plant.create!(name: "Overdue", min_watering_freq: 7, max_watering_freq: 14, project: project, uid: 123)
    plant.update!(date_last_watering: 20.days.ago.to_date, date_min_watering: 13.days.ago.to_date)
    assert plant.time_until_watering < 0
  end

  # ─── time_until_watering_text ───────────────────────────────────────────────

  test "time_until_watering_text returns never_watered message when no last watering" do
    project = Project.create!(name: "Test Project", owner: users(:one))
    plant = Plant.create!(name: "Never Watered Text", project: project, uid: 130)
    text = plant.time_until_watering_text
    # Should not raise and should return a non-empty string
    assert text.present?
  end

  test "time_until_watering_text returns unscheduled message when watered but no freq" do
    project = Project.create!(name: "Test Project", owner: users(:one))
    plant = Plant.create!(name: "Unscheduled Text", project: project, uid: 131)
    plant.update!(date_last_watering: 5.days.ago.to_date)
    text = plant.time_until_watering_text
    assert_equal I18n.t("plants.watering_status.unscheduled"), text
  end

  test "time_until_watering_text describes overdue plant" do
    project = Project.create!(name: "Test Project", owner: users(:one))
    plant = Plant.create!(name: "Late Text Plant", min_watering_freq: 7, max_watering_freq: 10, project: project, uid: 132)
    plant.update!(date_last_watering: 15.days.ago.to_date)
    text = plant.time_until_watering_text
    # Overdue: max_watering_days is negative
    assert text.present?
    assert_not_equal I18n.t("plants.watering_status.unscheduled"), text
  end

  test "time_until_watering_text describes plant due today" do
    project = Project.create!(name: "Test Project", owner: users(:one))
    plant = Plant.create!(name: "Today Text Plant", min_watering_freq: 7, max_watering_freq: 7, project: project, uid: 133)
    plant.update!(date_last_watering: 7.days.ago.to_date)
    text = plant.time_until_watering_text
    assert_equal I18n.t("plants.watering_status.today"), text
  end

  test "time_until_watering_text describes plant with equal min and max freq in future" do
    project = Project.create!(name: "Test Project", owner: users(:one))
    plant = Plant.create!(name: "In Days Text Plant", min_watering_freq: 7, max_watering_freq: 7, project: project, uid: 134)
    plant.update!(date_last_watering: 2.days.ago.to_date)
    text = plant.time_until_watering_text
    expected_days = 5
    assert_equal I18n.t("plants.watering_status.in_days", count: expected_days, days: expected_days), text
  end

  # ─── calculate_watering_frequency ──────────────────────────────────────────

  test "calculate_watering_frequency returns nil with fewer than 2 waterings" do
    project = Project.create!(name: "Test Project", owner: users(:one))
    plant = Plant.create!(name: "One Watering Plant", project: project, uid: 140)
    Watering.create!(plant: plant, watered_at: Time.zone.now)
    plant.reload
    result = plant.calculate_watering_frequency
    assert_nil result
  end

  test "calculate_watering_frequency with regular intervals sets min == max" do
    project = Project.create!(name: "Test Project", owner: users(:one))
    plant = Plant.create!(name: "Regular Plant", project: project, uid: 141)
    base = Time.zone.parse("2026-01-01 12:00:00")
    Watering.create!(plant: plant, watered_at: base)
    Watering.create!(plant: plant, watered_at: base + 7.days)
    Watering.create!(plant: plant, watered_at: base + 14.days)
    plant.reload
    plant.calculate_watering_frequency
    plant.reload

    assert_equal 7, plant.min_watering_freq
    assert_equal 7, plant.max_watering_freq
  end

  test "calculate_watering_frequency with irregular intervals sets min < max" do
    project = Project.create!(name: "Test Project", owner: users(:one))
    plant = Plant.create!(name: "Irregular Plant", project: project, uid: 142)
    base = Time.zone.parse("2026-01-01 12:00:00")
    Watering.create!(plant: plant, watered_at: base)
    Watering.create!(plant: plant, watered_at: base + 5.days)
    Watering.create!(plant: plant, watered_at: base + 15.days)  # 10 days gap
    plant.reload
    plant.calculate_watering_frequency
    plant.reload

    assert plant.min_watering_freq < plant.max_watering_freq
    assert_equal 5,  plant.min_watering_freq
    assert_equal 10, plant.max_watering_freq
  end

  test "calculate_watering_frequency returns nil with zero waterings" do
    project = Project.create!(name: "Test Project", owner: users(:one))
    plant = Plant.create!(name: "Empty Plant", project: project, uid: 143)
    result = plant.calculate_watering_frequency
    assert_nil result
  end

  # ─── watering_frequency_text ─────────────────────────────────────────────────

  test "watering_frequency_text returns empty string when no freq set" do
    project = Project.create!(name: "Test Project", owner: users(:one))
    plant = Plant.create!(name: "No Freq Plant", project: project, uid: 150)
    assert_equal '', plant.watering_frequency_text
  end

  test "watering_frequency_text returns 'Every N day(s)' when min == max" do
    project = Project.create!(name: "Test Project", owner: users(:one))
    plant = Plant.create!(name: "Equal Freq Plant", min_watering_freq: 7, max_watering_freq: 7, project: project, uid: 151)
    assert_equal "Every 7 days", plant.watering_frequency_text
  end

  test "watering_frequency_text returns 'N - M days' when min != max" do
    project = Project.create!(name: "Test Project", owner: users(:one))
    plant = Plant.create!(name: "Range Freq Plant", min_watering_freq: 5, max_watering_freq: 10, project: project, uid: 152)
    assert_equal "5 - 10 days", plant.watering_frequency_text
  end

  test "watering_frequency_text returns singular 'day' when freq is 1" do
    project = Project.create!(name: "Test Project", owner: users(:one))
    plant = Plant.create!(name: "Daily Plant", min_watering_freq: 1, max_watering_freq: 1, project: project, uid: 153)
    assert_equal "Every 1 day", plant.watering_frequency_text
  end

  # ─── last_watering ──────────────────────────────────────────────────────────

  test "last_watering returns the most recent watering by watered_at" do
    project = Project.create!(name: "Test Project", owner: users(:one))
    plant = Plant.create!(name: "Last Watering Plant", project: project, uid: 160)

    old_watering = Watering.create!(plant: plant, watered_at: 10.days.ago, notes: "Old watering")
    recent_watering = Watering.create!(plant: plant, watered_at: 1.day.ago, notes: "Recent watering")
    plant.reload

    assert_equal recent_watering, plant.last_watering,
      "last_watering should return the most recent watering, not an older one"
  end

  test "last_watering still returns most recent after editing an older watering" do
    project = Project.create!(name: "Test Project", owner: users(:one))
    plant = Plant.create!(name: "Edit Old Watering Plant", project: project, uid: 161)

    old_watering = Watering.create!(plant: plant, watered_at: 10.days.ago, notes: "Old notes")
    recent_watering = Watering.create!(plant: plant, watered_at: 1.day.ago, notes: "Recent notes")
    plant.reload

    # Edit the OLD watering — this should NOT change last_watering
    old_watering.update!(notes: "Edited old notes")
    plant.reload

    assert_equal recent_watering, plant.last_watering,
      "Editing an older watering should not change last_watering to that older watering"
    assert_equal "Recent notes", plant.last_watering.notes,
      "last_watering notes should be from the most recent watering"
  end

  test "last_watering updates correctly when a new watering is added with an earlier date" do
    project = Project.create!(name: "Test Project", owner: users(:one))
    plant = Plant.create!(name: "Backfill Watering Plant", project: project, uid: 162)

    recent_watering = Watering.create!(plant: plant, watered_at: 1.day.ago, notes: "Recent")
    plant.reload
    assert_equal recent_watering, plant.last_watering

    # Add a watering with an older date — last_watering should still be the recent one
    Watering.create!(plant: plant, watered_at: 10.days.ago, notes: "Backfilled old")
    plant.reload

    assert_equal recent_watering, plant.last_watering,
      "Adding a watering with an older date should not change last_watering"
  end

  test "last_watering data is used for Water Again link parameters" do
    project = Project.create!(name: "Test Project", owner: users(:one))
    recipe = Recipe.create!(name: "Test Recipe", project: project)
    plant = Plant.create!(name: "Water Again Plant", project: project, uid: 163)

    Watering.create!(plant: plant, watered_at: 10.days.ago, notes: "Old notes", volume: 1.0, units: "cups")
    recent = Watering.create!(plant: plant, watered_at: 1.day.ago, notes: "Recent notes", volume: 2.5, units: "mL", recipe: recipe, tds: 500)
    plant.reload

    # These are the fields used by plant_water_path in the views
    assert_equal "Recent notes", plant.last_watering.notes
    assert_equal 2.5, plant.last_watering.volume
    assert_equal "mL", plant.last_watering.units
    assert_equal recipe, plant.last_watering.recipe
    assert_equal 500, plant.last_watering.tds
  end
end
