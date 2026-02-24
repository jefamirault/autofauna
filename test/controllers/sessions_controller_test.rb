require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get new_session_url
    assert_response :success
  end

  test "should create session with valid credentials" do
    user = users(:one)
    post session_url, params: { user: { email: user.email, password: "password" } }
    assert_redirected_to plants_url
  end

  test "should reject invalid credentials" do
    post session_url, params: { user: { email: "wrong@example.com", password: "wrong" } }
    assert_response :unprocessable_entity
  end

  test "should destroy session" do
    sign_in users(:one)
    delete session_url
    assert_redirected_to new_session_url
  end
end
