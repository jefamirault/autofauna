# Testing (Minitest + Capybara)

```bash
cd /home/jef/autofauna && bin/rails test          # all tests
bin/rails test test/models                         # models only
bin/rails test:system                              # system tests (browser)
```

> Never run `bin/rails` yourself — instruct the user to run it and report back.

## Environment prerequisites

- **PostgreSQL superuser requirement:** Rails 8 added `check_all_foreign_keys_valid!`, which needs
  the DB user to have superuser privileges to access `pg_constraint`. The test DB user
  (`autofauna_development`) must be a superuser or tests error with `PG::InsufficientPrivilege`.
  One-time: `sudo -u postgres psql -c "ALTER USER autofauna_development WITH SUPERUSER;"`
- **Fixture FK ordering:** the DB user also can't disable referential integrity (needs superuser
  for trigger manipulation), so fixtures load in **alphabetical table order**. FK references in
  fixtures must point to tables that come earlier alphabetically, or the referenced column must be
  nullable (so it can be omitted).

## Test authentication

Auth uses encrypted cookies (`cookies.encrypted[:user_id]` / `[:project_id]`). Integration tests
authenticate via `sign_in(user)` in `test/test_helper.rb`:

```ruby
def sign_in(user)
  post session_url, params: { user: { email: user.email, password: "password" } }
end
```

- All authenticated controller tests call `sign_in` in `setup` before making requests.
- Fixture users use `password_digest: <%= BCrypt::Password.create('password') %>` so the hardcoded
  `"password"` works.
- `sign_in` also triggers `auto_select_project`, so `current_project` is set from the user's first
  project.
- The session route is **singular** (`resource :session`) → helpers are `new_session_url`,
  `session_url` (not `sessions_*`).

## Fixture conventions

- **Use fixture references, not hardcoded IDs:** `project: one`, not `project_id: 1`. Rails
  resolves labels to deterministic IDs via hashing.
- Fixture users need real BCrypt digests and unique emails.
- Fixture plants need unique `uid` per project (`validates_uniqueness_of :uid, scope: :project_id`).
- **Required associations:** Sensors require `zone` and `sensor_type`; Plants require `project`.
  Tanks require only `project` — `location` is optional (`belongs_to :location, optional: true`),
  since onboarding can create a tank before any locations exist.
- **Fixtures skip callbacks:** `after_save_commit` callbacks (`update_watering_dates`,
  `update_last_watering`) do NOT fire on fixture load. Computed fields (`date_last_watering`,
  `date_min_watering`, `last_watering_id`) are nil unless set explicitly in the fixture or computed
  in the test.
- **Onboarding:** users `one`/`two` have `onboarding_completed_at` set (**required** — otherwise
  every authenticated controller test redirects to onboarding). User `fresh` is non-onboarded
  (owns `projects(:project_fresh)`) for onboarding tests. See `docs/feature-flags.md`.

## Writing controller tests

```ruby
setup do
  @user = users(:one)
  @resource = resources(:one)
  sign_in @user
end
```

**Common pitfalls:**
- **No `assigns` in tests** — `rails-controller-testing` is not installed. Assert against the
  rendered response body (e.g. check that marker strings appear in the expected order).
- **Waterings new/edit** require a `plant_id` param: `get new_watering_url(plant_id: @watering.plant_id)`.
- **Destroy tests** may fail if the fixture has dependents with FK constraints — use a fixture
  without dependents (e.g. `zones(:two)`) or nil out the FK first
  (e.g. `@location.plants.update_all(location_id: nil)`).
- **Create/update tests** must include all required association params (e.g. `sensor_type_id` for
  sensors). `location_id` is optional for tanks.
- **Redirect assertions** must match controller behavior — waterings redirect to
  `plant_url(@watering.plant)`, not `watering_url`.
- **Transmit endpoint** is unauthenticated (API-key param) — set `api_key` on the project in setup.

## Multi-tenancy fixture "worlds"

Two worlds for cross-project isolation testing:

| Fixture | Project One (users :one) | Project Two (users :two) |
|---|---|---|
| Zone | `zones(:one)`, `zones(:two)` | `zones(:zone_p2)` |
| Location | `locations(:one)`, `locations(:two)` | `locations(:location_p2)` |
| Plant | `plants(:one)`, `plants(:two)` | `plants(:plant_p2)` |
| Watering | `waterings(:one)`, `waterings(:two)` | `waterings(:watering_p2)` |
| Tank | `tanks(:one)`, `tanks(:two)` | `tanks(:tank_p2)` |
| Sensor | `sensors(:one)`, `sensors(:two)` | `sensors(:sensor_p2)` |
| SensorType | `sensor_types(:one)`, `sensor_types(:two)` | `sensor_types(:sensor_type_p2)` |

Authorization tests verify `users(:two)` cannot access project-one resources (redirected via
`rescue_from RecordNotFound`).

## Coverage summary

| File | Tests | Covers |
|---|---|---|
| `test/controllers/*_controller_test.rb` | 54 | CRUD for all resource controllers (authenticated) |
| `test/controllers/authorization_test.rb` | 28 | Cross-project isolation (show/edit/update/destroy × 7 resources) |
| `test/controllers/shared_plants_controller_test.rb` | 7 | Share-token access, revocation, invalid tokens |
| `test/controllers/transmit_controller_test.rb` | 6 | Sensor API ingestion, bad keys, missing params |
| `test/models/plant_test.rb` | 28 | Watering schedule dates, urgency, frequency, text formatting |
| `test/models/user_notification_test.rb` | 20 | Notification frequency logic (daily/hourly/N-days) |
| `test/models/guest_account_test.rb` | 22 | Guest creation, conversion, merge, plants_needing_water |
