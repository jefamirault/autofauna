# Backing store for ActionController rate limiting (sessions, password resets,
# registrations, guests). The test environment's cache is :null_store, which
# would silently disable rate limiting, so tests get a real in-memory store —
# cleared between tests in test_helper.rb.
module RateLimiting
  STORE = Rails.env.test? ? ActiveSupport::Cache::MemoryStore.new : Rails.cache
end
