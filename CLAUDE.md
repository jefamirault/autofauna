# Autofauna

Plant care & environmental monitoring. Rails 8, multi-tenant with project-based collaboration.

> **How this file works:** This is the always-loaded orientation doc — stack, commands, and the
> cross-cutting *invariants* that keep the app correct. Feature-specific depth lives in `docs/`
> (read on demand) and in nested `CLAUDE.md` files (auto-loaded when you edit that directory). See
> **Deep Dives** at the bottom.
>
> **Keep this file lean.** If a fact only matters when editing one folder, it belongs in that
> folder's doc, not here. Two rules keep it from re-bloating:
> - **Write-time routing:** after a task, the narrative goes to `agent_log.md`; if a subsystem's
>   behavior changed, update its one doc; touch `CLAUDE.md` **only when a new invariant is created**.
> - **Gotcha expiry:** when a root cause is fixed, delete the gotcha in the same commit. Most bloat
>   is fixed-bug archaeology.
> - **Keep/cut test:** an *invariant* (must always hold, prevents bugs) stays here; a *description*
>   of how a feature currently works goes next to the code, or nowhere.

## Stack

Rails 8.0 / Ruby 3.2.2 · PostgreSQL · Hotwire (Turbo + Stimulus) · Importmap (no Node) ·
Sidekiq + Redis (sidekiq-cron) · SASS (sassc-rails) · Minitest + Capybara · Capistrano deploy.

Conventions: custom auth (no Devise, `has_secure_password`) · Google Sign-In (JWT, `google_uid`) ·
Ransack for search/filtering · guest accounts are real `User` rows (`guest: true`) ·
`advanced_mode` on User gates multi-project UI (hidden by default).

## Commands

```bash
cd /home/jef/autofauna && bin/rails <cmd>   # server | console | test | db:migrate | routes
cap production deploy
```

**Never run `bin/rails` yourself — instruct the user to run it and report back** (migrations,
tests, console, routes, server). The global `rails` binary is not this project's.

## Domain Model

```
User (has_secure_password, guest?, advanced_mode?, google_uid)
 └─ Collaboration (role) ─► Project (api_key, multi-tenant container)
      ├─ Zone
      │   └─ Location (color)
      │       └─ Plant (watering schedule, share tokens)
      │           ├─ Watering (watered_at DATETIME, tds, recipe_batch, recipe)
      │           └─ SoilMoistureReading (numeric/categorical, timing enum)
      ├─ Sensor (sensor_type)
      │   └─ HygroSensorReading
      ├─ PlantGroup (color, shared min/max freq) ─(join: plant_group_memberships)─ Plant
      ├─ Tank
      │   └─ WaterTest (jsonb parameters)
      ├─ RecipeSource (name, tank_id)
      │   └─ RecipeIngredient
      ├─ Recipe (name, color)
      │   ├─ RecipeIngredient (amount, units, position)
      │   └─ RecipeBatch (tds, volume, mixed_on, active)
      └─ PushSubscription (enabled, user_agent)
```

Key facts: `Watering.watered_at` is **DATETIME** not DATE. Plants carry watering frequency +
last-watering date. `Plant#quick_water!(at:)` holds the carry-forward logic shared by single,
group, and location bulk watering. `LogEntry` is polymorphic (`loggable`). Plants have two share
links (watering `share_token`, view-only `view_share_token`). Locations and Recipes have
user-assignable colors for UI filter buttons.

## Invariants (always hold — do not violate)

### Multi-tenant scoping (prevents IDOR)
- Every resource controller: `before_action :authenticate, :ensure_project` first, then
  `set_<resource>`, then `authorize_viewer`/`authorize_editor` (with `only:`/`except:`).
- **`set_*` scopes through the project:** `current_project.<assoc>.find(params[:id])` — never
  `Model.find`. Nested resources scope through the parent (`@tank.water_tests.find(...)`).
- `rescue_from ActiveRecord::RecordNotFound` in ApplicationController handles the 404 redirect.
- Public/shared controllers (share tokens) are the only exemption — they use `find_by` and handle
  not-found themselves.
- Mass-assignment of associations must filter to the project (e.g. `assign_plant_groups`,
  `assign_plant_recipes`) to prevent cross-project attach.

### Turbo Stream on the plants index
- Plant cards are **triple-rendered** (one per display mode; same `dom_id`). Turbo actions must use
  `replace_all` (CSS selector via `targets:`) **not** `replace` (single id), or only one instance
  updates.
- `button_to` inside `turbo-frame#plants-results` returns streams fine — do **not** add
  `data: { turbo_frame: "_top" }` (breaks the stream into a full navigation, reverting the update).
  Links that *navigate away* (plant show/edit) **do** need `_top`, or they show "Content Missing".

### Data-layer traps
- `Plant has_many :waterings` has a **default `order`** scope; use `reorder` when you need a
  different sort (it propagates through `current_project.waterings`).
- Watering `after_save_commit` (`update_last_watering`) may not have committed when a stream
  template renders — pass the new watering as an explicit local, don't read `plant.date_last_watering`.
- Diagram coordinates (`plants.layout_x/y`) are only meaningful on their own location's canvas.
  `Plant#clear_layout_on_location_change` nils them, but **any relocation done with `update_all`
  skips that callback** and must clear the columns itself (see `plants#bulk_set_location`).

## Testing (essentials — full reference in `test/CLAUDE.md`)

- Auth via encrypted cookies. Controller tests call `sign_in(user)` (helper in `test_helper.rb`)
  in `setup`; it also sets `current_project`.
- Fixture users `one`/`two` have `onboarding_completed_at` set (else every request redirects to
  onboarding); `fresh` is the non-onboarded user for onboarding tests.
- **DB user must be superuser** (`ALTER USER autofauna_development WITH SUPERUSER;`) or tests error
  on `check_all_foreign_keys_valid!`. Fixtures load in alphabetical table order (FK refs must point
  earlier or be nullable).
- Use fixture references (`project: one`), not IDs. No `assigns` (gem not installed) — assert on
  response body.

## Agent Log

Append a short summary of each significant task to `agent_log.md` (project root). When executing an
agreed plan, **write the plan to `agent_log.md` first**. The log is a chronological journal — never
reorganize it by topic (that's what `docs/` is for); its value is the record of what happened when.

**Rotate when the active log exceeds ~30 KB** (checkable at append time, same moment as write-time
routing), or on request. Rotation procedure: (1) move `agent_log.md` →
`agent_log/agent_log_<min-date>_to_<max-date>.md` (true earliest/latest entry dates — don't re-sort
out-of-order entries; concurrent sprint appends are an accurate record); (2) add a one-line entry
to `agent_log/README.md` (date range + topic hook); (3) create a fresh `agent_log.md`.

## Deep Dives (read on demand)

| When you're working on… | Read |
|---|---|
| Plants index (filters, display modes, multi-select, card fields) + Plant Groups & bulk watering | `docs/plants-index-ui.md` |
| Location diagram (drag-and-drop 2D plant layout, `plants.layout_x/y`, index mini-diagram) | `docs/location-diagram.md` |
| Header / sidebar / dynamic-header / responsive CSS + design-system classes | `docs/layout-css.md` |
| Feature flags & onboarding wizard | `docs/feature-flags.md` |
| Notifications (email + web push) | `docs/notifications.md` |
| Background jobs / Sidekiq | `docs/background-jobs.md` |
| Sensor API / transmit endpoint | `docs/api-sensors.md` |
| Deployment, server env, production Sidekiq, dev-env gotchas, plant graphics / Active Storage | `docs/deployment.md` |
| Auth, guests, merge, account deletion, Google Sign-In | `docs/auth-accounts.md` |
| Stimulus controllers (roster + cross-controller gotchas) | `app/javascript/controllers/CLAUDE.md` |
| Tests (fixtures, multi-tenancy worlds, coverage) | `test/CLAUDE.md` |
