# Autofauna

Plant care and environmental monitoring Rails app. Multi-tenant with project-based collaboration.

## Stack

- Rails 8.0 / Ruby 3.2.2
- PostgreSQL
- Hotwire (Turbo + Stimulus)
- Importmap (no Node/Webpack)
- Sidekiq + Redis (background jobs, cron via sidekiq-cron)
- Capistrano deployment (with capistrano-sidekiq)
- Minitest

## Commands

```bash
bin/rails server           # Start dev server
bin/rails console          # Rails console
bin/rails test             # Run tests
bin/rails db:migrate       # Run migrations
bin/rails routes           # Show routes

# Deployment
cap production deploy
```

**Note:** When running `rails` commands, use the project's `bin/rails` directly and ensure you `cd` into the project directory first. The global `rails` binary is not the project's — it will show `rails new` usage instead of running project commands.
- Chain with cd: `cd /home/jef/autofauna && bin/rails <command>`

## Domain Model

```
User (has_secure_password, guest?, advanced_mode?, google_uid, login_enabled)
 └── Collaboration (role) ──► Project (api_key, moisture_measurement_type)
                                ├── Zone
                                │    └── Location (color)
                                │         └── Plant (watering schedule, graphic, share_token, view_share_token)
                                │              ├── Watering (watered_at datetime, tds, recipe_batch, recipe)
                                │              └── SoilMoistureReading (numeric/categorical, timing enum)
                                ├── Sensor (sensor_type)
                                │    └── HygroSensorReading
                                ├── Tank
                                │    └── WaterTest (jsonb parameters)
                                ├── RecipeSource (name, tank_id)
                                │    └── RecipeIngredient
                                ├── Recipe (name, color)
                                │    ├── RecipeIngredient (amount, units, position)
                                │    └── RecipeBatch (tds, volume, volume_units, mixed_on, active)
                                └── PushSubscription (enabled, user_agent)
```

**Key relationships:**
- Projects are multi-tenant containers (owner_id + collaborations)
- Plants track watering frequency and last watering date (watered_at is DATETIME, not DATE)
- Plants can have a default Recipe; Waterings can reference a RecipeBatch + TDS
- RecipeSources are ingredients, Recipes compose them, RecipeBatches are specific mixes
- SoilMoistureReadings can be standalone or linked to waterings (pre/post timing)
- Sensors post readings via API (api_key on Project)
- LogEntries are polymorphic (loggable)
- Plants support two share links: watering (share_token) and view-only (view_share_token)
- Locations and Recipes have user-assignable colors for UI filter buttons

## Key Files

| Path | Purpose |
|------|---------|
| `app/models/` | Domain logic |
| `app/models/concerns/plant_graphics.rb` | Plant graphic selection (reads PNGs from `app/assets/images/plant_graphics/`) |
| `app/controllers/` | Request handling |
| `app/views/` | ERB templates |
| `app/helpers/application_helper.rb` | `header_config` (context-aware header gradient/icon/title per controller), `nav_label`/`nav_link`/`nav_item` |
| `app/javascript/controllers/` | Stimulus controllers |
| `config/routes.rb` | URL routing |
| `db/schema.rb` | Current DB structure |

## Conventions

- Custom auth (no Devise) - User has_secure_password
- Guest accounts: real User records with `guest: true`, convertible to full accounts
- Google Authentication via Google Identity Services (JWT verification, `google_uid` on User)
- `advanced_mode` flag on User controls visibility of multi-project UI (hidden by default)
- Ransack for search/filtering
- SASS for styles (sassc-rails)
- System tests with Capybara + Selenium

## Authorization & Resource Scoping

All resources are scoped to `current_project` to prevent cross-project access (IDOR). Follow these rules when adding or modifying controllers:

- **Every resource controller** must have `before_action :authenticate` and `before_action :ensure_project` (from ApplicationController) before any other filters
- **`set_*` methods must scope through `current_project`:** Use `current_project.<association>.find(params[:id])` — never `Model.find(params[:id])`. This returns 404 if the resource doesn't belong to the user's project.
- **Nested resources** scope through the parent: e.g. `@tank.water_tests.find(params[:id])`, where `@tank` was already scoped via `current_project.tanks.find(...)`
- **`authorize_viewer` / `authorize_editor`** come after `authenticate` and `ensure_project` in the filter chain
- **`rescue_from ActiveRecord::RecordNotFound`** in ApplicationController provides a user-friendly redirect when scoped `.find` raises
- **Public/shared controllers** (e.g. `SharedPlantsController`) are exempt — they use `find_by` with share tokens and handle not-found themselves

**Checklist for new controllers:**
1. `before_action :authenticate`
2. `before_action :ensure_project`
3. `before_action :set_<resource>` — scoped through `current_project`
4. `before_action :authorize_viewer` / `:authorize_editor` with appropriate `only:`/`except:`

## Design System (CSS Classes)

| Component | Usage | CSS Class |
|-----------|-------|-----------|
| Resource card | Index page list items (clickable) | `.resource-card` inside `.resource-cards` |
| Info card | Show page detail display | `.info-card` > `.info-card-grid` > `.info-card-section` with `.info-row` |
| Settings card | Edit/New form wrapper | `.settings-card` |
| Danger card | Destructive actions | `.settings-card.danger` |

## Background Jobs

- **Adapter:** Sidekiq (replaced Solid Queue)
- **Config:** `config/sidekiq.yml`, `config/initializers/sidekiq.rb`, `config/schedule.yml`
- **Redis:** `redis://localhost:6379/0` (default), configurable via `REDIS_URL` env var
- **Scheduled jobs:** `PlantNotificationJob` runs hourly (cron via sidekiq-cron)
- **Queues:** `default`, `mailers`
- **Dev workflow:** Start Redis + `bundle exec sidekiq` in separate terminal
- **Production:** Managed via capistrano-sidekiq (systemd service)

## Notifications

- **Email:** PlantNotificationMailer sends watering reminders via Mailgun SMTP
- **Push:** Web Push notifications via `web-push` gem + Service Worker (`public/service-worker.js`)
- **VAPID keys:** Stored in Rails credentials
- **Test buttons:** Settings page has "Send Test Email" and "Send Test Push Notification" buttons
- **Push subscription:** PushSubscription model (has `enabled` boolean), browser permission requested on enable
- **Per-device control:** Each push subscription can be individually disabled/enabled via inline toggle (no page reload). "Forget" deletes the record entirely.
- **Global ↔ device sync:** The push card header toggle and individual device states are bidirectionally synced:
  - Enabling the global toggle auto-enables the current device if all are disabled
  - Disabling the global toggle disables all devices
  - Disabling the last device auto-unchecks the global toggle (without collapsing the card)
  - Enabling any device auto-checks the global toggle
- **Notification sending** uses `PushSubscription.enabled` scope — disabled devices don't receive notifications
- **Test button states:** "Send Test Push" disabled (gray) when no enabled devices; "Send Test Email" disabled when email toggle is off

## Plants Index UI

The plants index is the main page with significant client-side interactivity:
- **Display modes:** Watering (flat list by urgency), Location (grouped), Recipe (grouped) — all rendered server-side, toggled client-side
- **Filters:** Status (Overdue/Needs Water/Scheduled), Recipe, Location — client-side with AND logic, toggleable visibility
- **Pagination:** Client-side, configurable per-page count
- **Search:** Debounced auto-submit via header search bar, with clear button
- **Plant cards:** Flexbox cards with urgency color coding, plant graphic, watering details, full-height water button
- **Key Stimulus controller:** `location_filter_controller.js` handles all filtering, pagination, display mode switching, and result count updates

## Stimulus Controllers

| Controller | Purpose |
|-----------|---------|
| `location_filter_controller` | Plants index: filtering (location/recipe/watering status), pagination, display mode, result counts |
| `collapsible_filters_controller` | Expand/collapse filter button rows (localStorage persistence) |
| `collapsible_group_controller` | Collapsible location/recipe groups (localStorage persistence) |
| `sidebar_controller` | Sidebar minimize/expand, mobile auto-close, icon-rail mode |
| `dropdown_controller` | Header user dropdown menu |
| `locale_popup_controller` | Sidebar locale switcher popup |
| `header_search_controller` | Debounced auto-submit for search |
| `plant_graphic_controller` | Graphic selection with live preview and auto-matching by name |
| `watering_recipe_controller` | Dynamic batch dropdown on recipe change, auto-fill TDS |
| `watering_moisture_controller` | Progressive disclosure of pre/post moisture fields |
| `nested_form_controller` | Add/remove rows for nested attributes (recipes) |
| `push_notification_controller` | Push device list: inline enable/disable toggle, "This Device" detection, test button state, global toggle sync |
| `notification_settings_controller` | Notification card: collapse/expand, frequency settings, dirty tracking, global enable/disable toggle, test button state |

## Layout Architecture

- **Grid layout:** `"sidebar header" / "sidebar main"` — sidebar spans both rows
- **Context-aware header:** Gradient color, icon, and title change per controller section (Plants=green, Waterings=blue, Tanks=teal, etc.) via `header_config` helper
- **Sidebar:** Minimized state = icon rail (4rem wide, emoji-only nav labels); expanded = full 18rem with text labels
- **FOUC prevention:** Inline `<script>` in `<head>` applies sidebar state before render
- **Mobile (≤600px):** Sidebar hidden when minimized, collapse button fixed-position; background-attachment: scroll
- **Plant graphic in header:** On plant/watering show pages, plant's graphic replaces section icon in header

## API / Sensor Integration

Projects have `api_key` for sensor data ingestion.

**Transmit endpoint** (`GET /transmit`):
```
/transmit?project_id=1&API_KEY=xxx&sensor_id=1&temp=72&humidity=45&error=optional
```
| Param | Required | Description |
|-------|----------|-------------|
| `project_id` | Yes | Project ID |
| `API_KEY` | Yes | Must match `project.api_key` |
| `sensor_id` | Yes | Sensor ID |
| `temp` | Yes | Temperature reading |
| `humidity` | Yes | Humidity reading |
| `error` | No | Error message if sensor failed |

**Other sensor routes:**
| Route | Purpose |
|-------|---------|
| `GET /sensor_readings` | View last 1000 readings (requires auth) |
| `POST /sensor_readings/import` | JSON file import |

## Key Routes

- `/plants` - Main resource (root), card-based index with client-side filtering/pagination
- `/plants/:id/water` - Quick watering action (carries forward last recipe/batch/TDS)
- `/plants/:plant_id/soil_moisture_readings` - Nested soil moisture logging
- `/shared/:share_token` - Public shared plant view (watering or view-only)
- `/recipe_sources` - Watering recipe ingredients
- `/recipes` - Watering recipe compositions
- `/recipe_batches` - Specific recipe mixes (with `for_recipe` JSON endpoint)
- `/projects` - Multi-tenant containers (redirects to plants for non-advanced users)
- `/zones` → `/locations` - Spatial hierarchy
- `/tanks/:tank_id/water_tests` - Nested water quality tests
- `/settings` - User preferences + test notification buttons
- `/guest` - Create anonymous guest account
- `/guest_conversion` - Convert guest to full account
- `/auth/google/callback` - Google sign-in callback

## Testing

```bash
bin/rails test                    # All tests
bin/rails test test/models        # Model tests only
bin/rails test:system             # System tests (browser)
```

**PostgreSQL superuser requirement:** Rails 8 added `check_all_foreign_keys_valid!` which requires the DB user to have superuser privileges to access `pg_constraint`. The test DB user (`autofauna_development`) must be a superuser or tests will error with `PG::InsufficientPrivilege`. One-time setup:
```bash
sudo -u postgres psql -c "ALTER USER autofauna_development WITH SUPERUSER;"
```

**Fixture FK ordering:** The DB user also cannot disable referential integrity (requires superuser for trigger manipulation), so fixtures load in alphabetical table order. FK references in fixtures must point to tables that come earlier alphabetically, or the referenced column must be nullable (so it can be omitted).

### Test Authentication

Auth uses encrypted cookies (`cookies.encrypted[:user_id]` and `cookies.encrypted[:project_id]`). Integration tests authenticate via a `sign_in(user)` helper defined in `test/test_helper.rb` that POSTs to `session_url` with credentials. All controller tests must call `sign_in` in `setup` before making requests.

```ruby
# test/test_helper.rb provides:
def sign_in(user)
  post session_url, params: { user: { email: user.email, password: "password" } }
end
```

- Fixture users use `password_digest: <%= BCrypt::Password.create('password') %>` so the hardcoded `"password"` works
- `sign_in` also triggers `auto_select_project`, so `current_project` is set automatically from the user's first project
- Session route is singular: `resource :session` → helpers are `new_session_url`, `session_url` (not `sessions_*`)

### Fixture Conventions

- **Use fixture references, not hardcoded IDs:** Write `project: one` not `project_id: 1`. Rails resolves fixture labels to deterministic IDs via hashing.
- **Fixture users** must have real BCrypt password digests and unique emails
- **Fixture plants** must have unique `uid` values (per project, validated by `validates_uniqueness_of :uid, scope: :project_id`)
- **Required associations:** Sensors require `zone` and `sensor_type`, Tanks require `location`, Plants require `project`
- **Fixtures skip callbacks:** `after_save_commit` callbacks (like `update_watering_dates`, `update_last_watering`) do NOT fire when fixtures are loaded. Computed fields like `date_last_watering`, `date_min_watering`, `last_watering_id` will be nil unless explicitly set in the fixture or computed manually in the test.

### Writing Controller Tests

All authenticated controller tests follow this pattern:

```ruby
setup do
  @user = users(:one)
  @resource = resources(:one)
  sign_in @user
end
```

**Common pitfalls:**
- **Waterings new/edit forms** require `plant_id` param: `get new_watering_url(plant_id: @watering.plant_id)`
- **Destroy tests** may fail if the fixture record has dependent associations with FK constraints. Either use a fixture without dependents (e.g., `zones(:two)`) or nil out the FK first (e.g., `@location.plants.update_all(location_id: nil)`)
- **Create/update tests** must include all required association params (e.g., `location_id` for tanks, `sensor_type_id` for sensors)
- **Redirect assertions** must match actual controller behavior — waterings redirect to `plant_url(@watering.plant)`, not `watering_url`
- **Transmit endpoint** is unauthenticated (uses API key param) — set `api_key` on the project in test setup

### Multi-Tenancy Test Fixtures

Two fixture "worlds" exist for cross-project isolation testing:

| Fixture | Project One (users :one) | Project Two (users :two) |
|---------|--------------------------|--------------------------|
| Zone | `zones(:one)`, `zones(:two)` | `zones(:zone_p2)` |
| Location | `locations(:one)`, `locations(:two)` | `locations(:location_p2)` |
| Plant | `plants(:one)`, `plants(:two)` | `plants(:plant_p2)` |
| Watering | `waterings(:one)`, `waterings(:two)` | `waterings(:watering_p2)` |
| Tank | `tanks(:one)`, `tanks(:two)` | `tanks(:tank_p2)` |
| Sensor | `sensors(:one)`, `sensors(:two)` | `sensors(:sensor_p2)` |
| SensorType | `sensor_types(:one)`, `sensor_types(:two)` | `sensor_types(:sensor_type_p2)` |

Authorization tests verify that `users(:two)` signed in cannot access project-one resources (redirected via `rescue_from RecordNotFound`).

### Test Coverage Summary

| File | Tests | What it covers |
|------|-------|----------------|
| `test/controllers/*_controller_test.rb` | 54 | CRUD for all resource controllers (authenticated) |
| `test/controllers/authorization_test.rb` | 28 | Cross-project isolation (show/edit/update/destroy × 7 resources) |
| `test/controllers/shared_plants_controller_test.rb` | 7 | Share token access, revocation, invalid tokens |
| `test/controllers/transmit_controller_test.rb` | 6 | Sensor API ingestion, bad keys, missing params |
| `test/models/plant_test.rb` | 28 | Watering schedule dates, urgency, frequency calc, text formatting |
| `test/models/user_notification_test.rb` | 20 | Notification frequency logic (daily/hourly/N-days) |
| `test/models/guest_account_test.rb` | 22 | Guest creation, conversion, merge, plants_needing_water |

## Agent Log

An `agent_log.md` file in the project root tracks changes made during the current session. After each significant task, append a summary to this file documenting what was changed and why.

**Plan execution:** When a plan is agreed upon and the user gives permission to clear context and execute, the **first step** must always be writing the plan to `agent_log.md` before any implementation begins.

When the user requests **rotating the logs**:
1. Move `agent_log.md` → `agent_log/agent_log_<start-date>_to_<end-date>.md` (using the date range of entries in the file)
2. Create a fresh `agent_log.md` in the project root

Archived logs live in the `agent_log/` directory.

## Deployment

Capistrano to production server:
```bash
cap production deploy
```

Config in `config/deploy.rb` and `config/deploy/production.rb`

**Server environment variables** are managed via rbenv-vars:
- Location: `/home/deploy/autofauna/.rbenv-vars`
- Contains: `RAILS_MASTER_KEY`, `REDIS_URL`, `MAILGUN_SMTP_USERNAME`, `MAILGUN_SMTP_PASSWORD`
- If credentials are regenerated locally, update `RAILS_MASTER_KEY` on server
- VAPID keys for push notifications stored in Rails credentials

**Sidekiq in production:**
- Managed via systemd service (`/etc/systemd/system/sidekiq.service`)
- Config: `config/deploy.rb` has sidekiq settings (config path, log path, pid path)
- Logs: `/home/deploy/autofauna/log/sidekiq.log`, errors: `/home/deploy/autofauna/log/sidekiq_error.log`
- Working directory: `/home/deploy/autofauna/current` (Capistrano symlink — NOT `/home/deploy/autofauna`)
- ExecStart uses `/home/deploy/.rbenv/bin/rbenv exec bundle exec sidekiq` (rbenv not in systemd PATH by default)
- **Stale processes:** After deploy, an old Sidekiq process may still be running with outdated code. Check `ps aux | grep sidekiq` — if a process predates the deploy, kill it and restart via `sudo systemctl restart sidekiq`
- **Debugging:** `sudo systemctl status sidekiq` for status, `sudo journalctl -u sidekiq -n 30 --no-pager` for logs
- **Running rails commands on server:** Must use `/home/deploy/autofauna/current` (not `/home/deploy/autofauna`), e.g. `cd /home/deploy/autofauna/current && RAILS_ENV=production bin/rails db:migrate`

## Common Patterns & Gotchas

- **Turbo Frame issues:** Links inside `<turbo-frame>` need `data: { turbo_frame: "_top" }` to break out of frame context, otherwise they show "Content Missing"
- **Google Sign-In + Turbo:** Must manually call `google.accounts.id.initialize()` + `renderButton()` on `turbo:load` events (in `application.js`)
- **Google Sign-In ux_mode:** Must include `ux_mode: "redirect"` in manual `initialize()` calls to match HTML config
- **Rails `prompt:` vs `include_blank:`** on `collection_select`: `prompt:` only shows when value is nil; `include_blank:` always shows (use for "None" option on edit forms)
- **`params[:q]` with Ransack:** Use `params[:q]&.to_unsafe_h` when passing search params to URL helpers
- **Watering date:** Column is `watered_at` (DATETIME), not `date` (DATE) — changed in migration `20260220100002`
- **N+1 on plants index:** Use `.includes(:location, :recipe, :last_watering)` on Ransack result
- **Guest cleanup:** `rake guests:cleanup` destroys guest accounts older than 30 days
- **Account deletion:** Async via `DeleteUserDataJob` — sets `login_enabled: false` immediately, destroys data in background
- **Merge guest data:** When guest authenticates with existing account, `merge_guest!` transfers all data (plants, zones, sensors, etc.)
- **Push subscription dual state:** Browser push subscriptions and server `PushSubscription` records are independent. The server record has an `enabled` flag to soft-disable without deleting. "Forget" deletes the record entirely. If browser is subscribed but no server record exists, the JS auto-re-registers. If a disabled record exists for the endpoint, it does NOT re-register (the endpoint still matches).
- **Push device "Forget" button:** Only visible when the device is disabled; never shown for the current device (CSS `!important` rule on `.current-device .push-device-forget-wrap`)
- **Cross-controller communication (push):** `notification-settings` dispatches `notification-enabled`/`notification-disabled` custom events on the `push-notification` controller element. The push controller listens in `connect()`. A `_suppressHeaderSync` flag prevents feedback loops when the global toggle triggers bulk device changes.
- **Notification card collapse:** The `notification-settings` controller collapses card bodies to `height: 0; overflow: hidden`. Stimulus controllers inside still connect and can inject DOM, but content is invisible until the toggle switch expands the body. Don't remove visible fallback UI (like subscribe buttons) without ensuring the JS replacement works in both collapsed and expanded states
- **button_to data attributes:** Rails `button_to` puts `data:` attributes on the `<form>` wrapper, not the `<button>`. To target the actual button from Stimulus, wrap in a div with the target and use `querySelector("button[type='submit']")` inside.
- **button_to generates `<form>` tags:** Rails `button_to` renders a `<form>` element in the DOM. When using `querySelector("form")` inside a Stimulus controller, `button_to` forms may be found instead of the intended form. The push notification card has `button_to "Forget"` forms before the frequency settings form, so `querySelector("form")` returns the wrong one. Prefer querying for the specific input directly on `this.element` (e.g., `this.element.querySelector('input[type="time"]')`) or use Stimulus targets instead of generic form queries.
