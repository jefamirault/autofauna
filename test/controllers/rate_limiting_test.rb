require "test_helper"

# Rate limits use RateLimiting::STORE (a real memory store in test); the global
# setup in test_helper clears it before each test.
class RateLimitingTest < ActionDispatch::IntegrationTest
  test "repeated login attempts from one IP return 429" do
    11.times do |i|
      post session_url, params: { user: { email: "attacker#{i}@example.com", password: "wrong" } }
    end
    assert_response :too_many_requests
  end

  test "repeated login attempts against one email return 429 even from different IPs" do
    11.times do |i|
      post session_url,
        params: { user: { email: users(:one).email, password: "wrong" } },
        headers: { "REMOTE_ADDR" => "203.0.113.#{i + 1}" }
    end
    assert_response :too_many_requests
  end

  test "login under the limit is not throttled" do
    9.times do
      post session_url, params: { user: { email: "someone@example.com", password: "wrong" } }
    end
    post session_url, params: { user: { email: users(:one).email, password: "password" } }
    assert_redirected_to plants_path
  end

  test "repeated password reset requests for one email return 429" do
    6.times do
      post password_reset_url, params: { user: { email: users(:one).email } }
    end
    assert_response :too_many_requests
  end

  test "password reset limit is per email" do
    5.times do
      post password_reset_url, params: { user: { email: users(:one).email } }
    end
    post password_reset_url, params: { user: { email: users(:two).email } }
    assert_redirected_to new_session_path
  end

  test "repeated registrations from one IP return 429" do
    11.times do |i|
      post registrations_url, params: { user: {
        email: "new#{i}@example.com", password: "password", password_confirmation: "password"
      } }
    end
    assert_response :too_many_requests
  end

  test "guest account creation is bounded per IP" do
    assert_difference "User.count", 10 do
      11.times { post "/guest" }
    end
    assert_response :too_many_requests
  end
end
