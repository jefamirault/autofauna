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
                                └── PushSubscription
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
- **Push subscription:** PushSubscription model, browser permission requested on enable

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
- Managed via capistrano-sidekiq (auto-creates systemd service)
- Config: `config/deploy.rb` has sidekiq settings (config path, log path, pid path)
- Logs: `/home/jef/autofauna/log/sidekiq.log`

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
