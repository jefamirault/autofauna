ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Rate-limit counters live in a process-wide memory store; clear them so a
  # test's requests (incl. sign_in) never trip limits accumulated by earlier tests.
  setup do
    RateLimiting::STORE.clear
  end

  # Add more helper methods to be used by all tests here...
end

class ActionDispatch::IntegrationTest
  def sign_in(user)
    post session_url, params: { user: { email: user.email, password: "password" } }
  end
end
