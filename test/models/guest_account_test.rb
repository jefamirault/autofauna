require "test_helper"

class GuestAccountTest < ActiveSupport::TestCase
  # ---------------------------------------------------------------------------
  # Guest creation
  # ---------------------------------------------------------------------------

  test "guest user has guest flag set to true" do
    guest = User.create!(guest: true)
    assert guest.guest?
  end

  test "guest user does not require email" do
    guest = User.create!(guest: true)
    assert_nil guest.email
  end

  test "guest user does not require password" do
    guest = User.create!(guest: true)
    assert_nil guest.password_digest
  end

  test "guest user gets a default project via after_create callback" do
    guest = User.create!(guest: true)
    assert_equal 1, guest.projects.count
    assert_equal "My Plants", guest.projects.first.name
  end

  # ---------------------------------------------------------------------------
  # convert_from_guest!
  # ---------------------------------------------------------------------------

  test "convert_from_guest! sets guest to false and saves email and password" do
    guest = User.create!(guest: true)
    guest.convert_from_guest!(
      email: "converted@example.com",
      password: "securepass",
      password_confirmation: "securepass"
    )
    guest.reload
    assert_not guest.guest?
    assert_equal "converted@example.com", guest.email
    assert guest.authenticate("securepass")
  end

  test "convert_from_guest! raises if called on a non-guest account" do
    user = users(:one)
    assert_raises(RuntimeError, "Not a guest account") do
      user.convert_from_guest!(
        email: "newemail@example.com",
        password: "securepass",
        password_confirmation: "securepass"
      )
    end
  end

  test "convert_from_guest! raises if email is blank" do
    guest = User.create!(guest: true)
    assert_raises(ActiveRecord::RecordInvalid) do
      guest.convert_from_guest!(
        email: "",
        password: "securepass",
        password_confirmation: "securepass"
      )
    end
  end

  test "convert_from_guest! raises if password is too short" do
    guest = User.create!(guest: true)
    assert_raises(ActiveRecord::RecordInvalid) do
      guest.convert_from_guest!(
        email: "valid@example.com",
        password: "abc",
        password_confirmation: "abc"
      )
    end
  end

  # ---------------------------------------------------------------------------
  # convert_from_guest_google!
  # ---------------------------------------------------------------------------

  test "convert_from_guest_google! sets guest to false and saves google_uid" do
    guest = User.create!(guest: true)
    guest.convert_from_guest_google!(
      email: "googleuser@example.com",
      google_uid: "google-uid-123",
      avatar_url: "https://example.com/avatar.png"
    )
    guest.reload
    assert_not guest.guest?
    assert_equal "googleuser@example.com", guest.email
    assert_equal "google-uid-123", guest.google_uid
  end

  test "convert_from_guest_google! generates a random password_digest" do
    guest = User.create!(guest: true)
    assert_nil guest.password_digest
    guest.convert_from_guest_google!(
      email: "googleuser2@example.com",
      google_uid: "google-uid-456"
    )
    guest.reload
    assert_not_nil guest.password_digest
  end

  test "convert_from_guest_google! raises if called on a non-guest account" do
    user = users(:one)
    assert_raises(RuntimeError, "Not a guest account") do
      user.convert_from_guest_google!(
        email: "googleuser@example.com",
        google_uid: "google-uid-789"
      )
    end
  end

  # ---------------------------------------------------------------------------
  # merge_guest!
  # ---------------------------------------------------------------------------

  test "merge_guest! raises if source is not a guest" do
    target = users(:one)
    non_guest = users(:two)
    assert_raises(RuntimeError, "Source must be a guest") do
      target.merge_guest!(non_guest)
    end
  end

  test "merge_guest! transfers plants to target user's project for non-advanced users" do
    target = users(:one)
    guest = User.create!(guest: true)
    guest_project = guest.projects.first
    plant = Plant.create!(name: "Guest Plant", uid: 1, project: guest_project)

    target_project = target.projects.first
    initial_count = target_project.plants.count

    target.merge_guest!(guest)

    target_project.reload
    assert_equal initial_count + 1, target_project.plants.count
    assert target_project.plants.exists?(name: "Guest Plant")
  end

  test "merge_guest! reassigns plant UIDs to avoid conflicts" do
    target = users(:one)
    target_project = target.projects.first
    # ensure there's a plant in the target project to set max_uid
    existing_plant = Plant.create!(name: "Existing Plant", uid: 10, project: target_project)

    guest = User.create!(guest: true)
    guest_project = guest.projects.first
    Plant.create!(name: "Guest Plant A", uid: 1, project: guest_project)
    Plant.create!(name: "Guest Plant B", uid: 2, project: guest_project)

    target.merge_guest!(guest)

    target_project.reload
    merged_plants = target_project.plants.where(name: [ "Guest Plant A", "Guest Plant B" ]).order(:uid)
    assert_equal 11, merged_plants.first.uid
    assert_equal 12, merged_plants.last.uid
  end

  test "merge_guest! transfers zones to target project for non-advanced users" do
    target = users(:one)
    guest = User.create!(guest: true)
    guest_project = guest.projects.first
    Zone.create!(name: "Guest Zone", project: guest_project)

    target_project = target.projects.first
    initial_count = target_project.zones.count

    target.merge_guest!(guest)

    target_project.reload
    assert_equal initial_count + 1, target_project.zones.count
  end

  test "merge_guest! transfers locations to target project for non-advanced users" do
    target = users(:one)
    guest = User.create!(guest: true)
    guest_project = guest.projects.first
    zone = Zone.create!(name: "Guest Zone", project: guest_project)
    Location.create!(name: "Guest Location", project: guest_project, zone: zone)

    target_project = target.projects.first
    initial_count = target_project.locations.count

    target.merge_guest!(guest)

    target_project.reload
    assert_equal initial_count + 1, target_project.locations.count
  end

  test "merge_guest! transfers sensors to target project for non-advanced users" do
    target = users(:one)
    guest = User.create!(guest: true)
    guest_project = guest.projects.first
    zone = Zone.create!(name: "Guest Zone", project: guest_project)
    sensor_type = SensorType.create!(name: "Guest Type", project: guest_project)
    Sensor.create!(name: "Guest Sensor", project: guest_project, zone: zone, sensor_type: sensor_type)

    target_project = target.projects.first
    initial_count = target_project.sensors.count

    target.merge_guest!(guest)

    target_project.reload
    assert_equal initial_count + 1, target_project.sensors.count
  end

  test "merge_guest! transfers non-overlapping collaborations" do
    target = users(:one)
    guest = User.create!(guest: true)
    other_project = projects(:two)
    collab = Collaboration.create!(user: guest, project: other_project, role: :viewer)

    target.merge_guest!(guest)

    collab.reload
    assert_equal target.id, collab.user_id
  end

  test "merge_guest! does not transfer collaborations that overlap with existing ones" do
    target = users(:one)
    guest = User.create!(guest: true)
    shared_project = projects(:two)
    Collaboration.create!(user: target, project: shared_project, role: :editor)
    guest_collab = Collaboration.create!(user: guest, project: shared_project, role: :viewer)

    target.merge_guest!(guest)

    # overlapping collaboration should remain with original user_id (or be destroyed via guest destroy)
    assert_raises(ActiveRecord::RecordNotFound) { guest_collab.reload }
  end

  test "merge_guest! transfers log entries to target user" do
    target = users(:one)
    guest = User.create!(guest: true)
    guest_project = guest.projects.first
    plant = Plant.create!(name: "Log Plant", uid: 1, project: guest_project)
    log = LogEntry.create!(
      entry_type: "note",
      description: "A note",
      loggable: plant,
      user: guest,
      timestamp: Time.current
    )

    target.merge_guest!(guest)

    log.reload
    assert_equal target.id, log.user_id
  end

  test "merge_guest! destroys the guest user after merge" do
    target = users(:one)
    guest = User.create!(guest: true)
    guest_id = guest.id

    target.merge_guest!(guest)

    assert_raises(ActiveRecord::RecordNotFound) { User.find(guest_id) }
  end

  test "merge_guest! with advanced_mode transfers guest projects to target user" do
    target = users(:one)
    target.update!(advanced_mode: true)

    guest = User.create!(guest: true)
    guest_project = guest.projects.first
    guest_project_id = guest_project.id

    target.merge_guest!(guest)

    guest_project.reload
    assert_equal target.id, guest_project.owner_id
  end

  # ---------------------------------------------------------------------------
  # plants_needing_water
  # ---------------------------------------------------------------------------

  test "plants_needing_water returns plants from owned projects due today or earlier" do
    user = users(:one)
    project = user.projects.first
    plant = Plant.create!(
      name: "Thirsty Plant",
      uid: 99,
      project: project,
      date_sort_watering: Date.current
    )

    result = user.plants_needing_water
    assert_includes result, plant
  end

  test "plants_needing_water excludes archived plants" do
    user = users(:one)
    project = user.projects.first
    archived_plant = Plant.create!(
      name: "Archived Plant",
      uid: 98,
      project: project,
      archived: true,
      date_sort_watering: Date.current
    )

    result = user.plants_needing_water
    assert_not_includes result, archived_plant
  end

  test "plants_needing_water excludes plants with no date_sort_watering" do
    user = users(:one)
    project = user.projects.first
    unscheduled = Plant.create!(
      name: "Unscheduled Plant",
      uid: 97,
      project: project,
      date_sort_watering: nil
    )

    result = user.plants_needing_water
    assert_not_includes result, unscheduled
  end

  test "plants_needing_water excludes plants scheduled for the future" do
    user = users(:one)
    project = user.projects.first
    future_plant = Plant.create!(
      name: "Future Plant",
      uid: 96,
      project: project,
      date_sort_watering: Date.current + 3.days
    )

    result = user.plants_needing_water
    assert_not_includes result, future_plant
  end

  test "plants_needing_water includes plants from collaborated projects" do
    user = users(:one)
    other_project = projects(:two)
    Collaboration.create!(user: user, project: other_project, role: :viewer)
    plant = Plant.create!(
      name: "Collab Plant",
      uid: 95,
      project: other_project,
      date_sort_watering: Date.current
    )

    result = user.plants_needing_water
    assert_includes result, plant
  end
end
