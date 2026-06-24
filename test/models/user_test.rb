require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "enable_feature! turns a flag on" do
    user = users(:one)
    user.update!(precise_measurements: false)

    user.enable_feature!(:precise_measurements)
    assert user.reload.precise_measurements?
  end

  test "enable_feature! is a no-op when already enabled" do
    user = users(:one)
    user.update!(track_waterings: true)

    assert_nothing_raised { user.enable_feature!(:track_waterings) }
    assert user.reload.track_waterings?
  end

  test "enable_feature! accepts string flag names" do
    user = users(:one)
    user.update!(has_aquarium: false)

    user.enable_feature!("has_aquarium")
    assert user.reload.has_aquarium?
  end

  test "enable_feature! rejects unknown flags" do
    assert_raises(ArgumentError) { users(:one).enable_feature!(:not_a_flag) }
  end
end
