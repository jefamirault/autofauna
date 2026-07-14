require "test_helper"

class ContentSecurityPolicyTest < ActionDispatch::IntegrationTest
  test "responses carry a report-only CSP header" do
    get new_session_url
    policy = response.headers["Content-Security-Policy-Report-Only"]
    assert policy.present?, "expected a report-only CSP header"
    assert_includes policy, "default-src 'self'"
    assert_match /script-src[^;]*'nonce-/, policy
    assert_match /script-src[^;]*https:\/\/accounts\.google\.com/, policy
  end

  test "layout inline scripts carry the CSP nonce" do
    get new_session_url
    assert_match /<script nonce="[^"]+">/, response.body
    # No inline event-handler attributes on the GSI script tag (a code comment
    # mentioning onload= is fine; an onload="..." attribute is not).
    assert_no_match /\sonload="/, response.body
  end
end
