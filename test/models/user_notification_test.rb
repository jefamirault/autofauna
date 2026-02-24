require "test_helper"

class UserNotificationTest < ActiveSupport::TestCase
  # Helper to build a user with notification attributes set explicitly.
  # We use users(:one) as a base and assign attributes without saving to DB,
  # since we're only calling pure-Ruby logic on `should_send_notification?`.
  def notification_user(attrs = {})
    user = users(:one)
    defaults = {
      email_notifications_enabled: true,
      push_notifications_enabled: true,
      email_notification_time: Time.zone.parse("09:00"),
      push_notification_time: Time.zone.parse("09:00"),
      email_notification_frequency_type: "daily",
      push_notification_frequency_type: "daily",
      email_notification_frequency_value: 1,
      push_notification_frequency_value: 1,
      last_email_notification_sent_at: nil,
      last_push_notification_sent_at: nil
    }
    defaults.merge(attrs).each { |k, v| user.send("#{k}=", v) }
    user
  end

  # ---------------------------------------------------------------------------
  # Disabled notifications
  # ---------------------------------------------------------------------------

  test "returns false for email channel when email_notifications_enabled is false" do
    user = notification_user(email_notifications_enabled: false)
    travel_to Time.zone.parse("2026-02-23 09:00:00") do
      assert_not user.should_send_notification?(:email)
    end
  end

  test "returns false for push channel when push_notifications_enabled is false" do
    user = notification_user(push_notifications_enabled: false)
    travel_to Time.zone.parse("2026-02-23 09:00:00") do
      assert_not user.should_send_notification?(:push)
    end
  end

  # ---------------------------------------------------------------------------
  # Daily frequency
  # ---------------------------------------------------------------------------

  test "daily: returns true at the correct hour and minute when not yet sent today" do
    user = notification_user(
      email_notification_frequency_type: "daily",
      email_notification_time: Time.zone.parse("09:00"),
      last_email_notification_sent_at: nil
    )
    travel_to Time.zone.parse("2026-02-23 09:00:00") do
      assert user.should_send_notification?(:email)
    end
  end

  test "daily: returns false if already sent today" do
    user = notification_user(
      email_notification_frequency_type: "daily",
      email_notification_time: Time.zone.parse("09:00"),
      last_email_notification_sent_at: Time.zone.parse("2026-02-23 09:00:00")
    )
    travel_to Time.zone.parse("2026-02-23 09:00:00") do
      assert_not user.should_send_notification?(:email)
    end
  end

  test "daily: returns false at wrong time of day" do
    user = notification_user(
      email_notification_frequency_type: "daily",
      email_notification_time: Time.zone.parse("09:00"),
      last_email_notification_sent_at: nil
    )
    travel_to Time.zone.parse("2026-02-23 10:00:00") do
      assert_not user.should_send_notification?(:email)
    end
  end

  test "daily: returns true the next day after being sent yesterday" do
    user = notification_user(
      email_notification_frequency_type: "daily",
      email_notification_time: Time.zone.parse("09:00"),
      last_email_notification_sent_at: Time.zone.parse("2026-02-22 09:00:00")
    )
    travel_to Time.zone.parse("2026-02-23 09:00:00") do
      assert user.should_send_notification?(:email)
    end
  end

  # ---------------------------------------------------------------------------
  # Hourly frequency
  # ---------------------------------------------------------------------------

  test "hourly: returns true at correct interval when never sent" do
    # Start time 09:00, every 2 hours => fires at 09:00, 11:00, 13:00 ...
    user = notification_user(
      email_notification_frequency_type: "hourly",
      email_notification_time: Time.zone.parse("09:00"),
      email_notification_frequency_value: 2,
      last_email_notification_sent_at: nil
    )
    travel_to Time.zone.parse("2026-02-23 11:00:00") do
      assert user.should_send_notification?(:email)
    end
  end

  test "hourly: returns true at start time on first send" do
    user = notification_user(
      email_notification_frequency_type: "hourly",
      email_notification_time: Time.zone.parse("09:00"),
      email_notification_frequency_value: 2,
      last_email_notification_sent_at: nil
    )
    travel_to Time.zone.parse("2026-02-23 09:00:00") do
      assert user.should_send_notification?(:email)
    end
  end

  test "hourly: returns false between intervals" do
    user = notification_user(
      email_notification_frequency_type: "hourly",
      email_notification_time: Time.zone.parse("09:00"),
      email_notification_frequency_value: 2,
      last_email_notification_sent_at: nil
    )
    travel_to Time.zone.parse("2026-02-23 10:00:00") do
      assert_not user.should_send_notification?(:email)
    end
  end

  test "hourly: returns false before start time" do
    user = notification_user(
      email_notification_frequency_type: "hourly",
      email_notification_time: Time.zone.parse("09:00"),
      email_notification_frequency_value: 2,
      last_email_notification_sent_at: nil
    )
    travel_to Time.zone.parse("2026-02-23 08:00:00") do
      assert_not user.should_send_notification?(:email)
    end
  end

  test "hourly: returns false if already sent this minute" do
    user = notification_user(
      email_notification_frequency_type: "hourly",
      email_notification_time: Time.zone.parse("09:00"),
      email_notification_frequency_value: 2,
      last_email_notification_sent_at: Time.zone.parse("2026-02-23 11:00:00")
    )
    travel_to Time.zone.parse("2026-02-23 11:00:30") do
      assert_not user.should_send_notification?(:email)
    end
  end

  test "hourly: returns true at next interval after a send" do
    user = notification_user(
      email_notification_frequency_type: "hourly",
      email_notification_time: Time.zone.parse("09:00"),
      email_notification_frequency_value: 2,
      last_email_notification_sent_at: Time.zone.parse("2026-02-23 11:00:00")
    )
    travel_to Time.zone.parse("2026-02-23 13:00:00") do
      assert user.should_send_notification?(:email)
    end
  end

  # ---------------------------------------------------------------------------
  # N-days frequency
  # ---------------------------------------------------------------------------

  test "days: returns true on first send (last_sent is nil) at correct time" do
    user = notification_user(
      email_notification_frequency_type: "days",
      email_notification_time: Time.zone.parse("09:00"),
      email_notification_frequency_value: 3,
      last_email_notification_sent_at: nil
    )
    travel_to Time.zone.parse("2026-02-23 09:00:00") do
      assert user.should_send_notification?(:email)
    end
  end

  test "days: returns true when enough days have passed since last send" do
    user = notification_user(
      email_notification_frequency_type: "days",
      email_notification_time: Time.zone.parse("09:00"),
      email_notification_frequency_value: 3,
      last_email_notification_sent_at: Time.zone.parse("2026-02-19 09:00:00")
    )
    # 2026-02-19 + 3 days = 2026-02-22; end_of_day of 2026-02-22 is 2026-02-22 23:59:59
    # now = 2026-02-23 09:00 > end_of_day(2026-02-22), so should be true
    travel_to Time.zone.parse("2026-02-23 09:00:00") do
      assert user.should_send_notification?(:email)
    end
  end

  test "days: returns false when not enough days have passed" do
    user = notification_user(
      email_notification_frequency_type: "days",
      email_notification_time: Time.zone.parse("09:00"),
      email_notification_frequency_value: 3,
      last_email_notification_sent_at: Time.zone.parse("2026-02-21 09:00:00")
    )
    # 2026-02-21 + 3 days = 2026-02-24; end_of_day = 2026-02-24 23:59:59
    # now = 2026-02-23 09:00 < that, so should be false
    travel_to Time.zone.parse("2026-02-23 09:00:00") do
      assert_not user.should_send_notification?(:email)
    end
  end

  test "days: returns false at wrong time even when enough days have passed" do
    user = notification_user(
      email_notification_frequency_type: "days",
      email_notification_time: Time.zone.parse("09:00"),
      email_notification_frequency_value: 3,
      last_email_notification_sent_at: Time.zone.parse("2026-02-19 09:00:00")
    )
    travel_to Time.zone.parse("2026-02-23 10:00:00") do
      assert_not user.should_send_notification?(:email)
    end
  end

  # ---------------------------------------------------------------------------
  # Push channel mirrors email logic (spot-check)
  # ---------------------------------------------------------------------------

  test "push daily: returns true at correct time when not yet sent" do
    user = notification_user(
      push_notification_frequency_type: "daily",
      push_notification_time: Time.zone.parse("09:00"),
      last_push_notification_sent_at: nil
    )
    travel_to Time.zone.parse("2026-02-23 09:00:00") do
      assert user.should_send_notification?(:push)
    end
  end

  test "push daily: returns false if already sent today" do
    user = notification_user(
      push_notification_frequency_type: "daily",
      push_notification_time: Time.zone.parse("09:00"),
      last_push_notification_sent_at: Time.zone.parse("2026-02-23 09:00:00")
    )
    travel_to Time.zone.parse("2026-02-23 09:00:00") do
      assert_not user.should_send_notification?(:push)
    end
  end

  test "push hourly: returns false when push disabled even at correct interval" do
    user = notification_user(
      push_notifications_enabled: false,
      push_notification_frequency_type: "hourly",
      push_notification_time: Time.zone.parse("09:00"),
      push_notification_frequency_value: 1,
      last_push_notification_sent_at: nil
    )
    travel_to Time.zone.parse("2026-02-23 09:00:00") do
      assert_not user.should_send_notification?(:push)
    end
  end
end
