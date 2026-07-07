# Background Jobs (Sidekiq)

- **Adapter:** Sidekiq (replaced Solid Queue).
- **Config:** `config/sidekiq.yml`, `config/initializers/sidekiq.rb`, `config/schedule.yml`.
- **Redis:** `redis://localhost:6379/0` (default), configurable via `REDIS_URL`.
- **Scheduled jobs:** `PlantNotificationJob` runs hourly (cron via sidekiq-cron).
- **Queues:** `default`, `mailers`.
- **Dev workflow:** start Redis + `bundle exec sidekiq` in a separate terminal.
- **Production:** managed via capistrano-sidekiq (systemd service) — see `docs/deployment.md` for
  the systemd unit, stale-process caveat, and debugging commands.

## Async work triggered elsewhere

- **Account deletion** is async via `DeleteUserDataJob` — sets `login_enabled: false` immediately,
  destroys data in the background. See `docs/auth-accounts.md`.
- **Newly-bundled gems require a Sidekiq restart** (as well as the web server) — a long-lived
  worker loads its gems once at boot. See the dev-environment section of `docs/deployment.md`.
