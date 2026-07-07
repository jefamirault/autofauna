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
                                ├── PlantGroup (color, shared min/max watering freq)
                                │    └── PlantGroupMembership ──► Plant (many-to-many)
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
- Plants can belong to many **PlantGroups** (`plant_group_memberships` join). Groups are project-scoped, colored, with an optional shared watering schedule (min/max freq). See "Plant Groups & Group Watering".

## Plant Groups & Group Watering

Plants can be watered one-at-a-time or in bulk. Bulk watering reuses **`Plant#quick_water!(at:)`** (the carry-forward logic — copies the last watering's volume/units/notes/recipe/batch/tds — extracted from `PlantsController#quick_water` so single and group watering share it).

- **Two grouping mechanisms (both supported):**
  - **Locations as implicit groups** — `Location#water_all!` waters every non-archived plant in the location. The plants index renders a "💧 Water all" `button_to` (`water_all_location_path`) in each location group header (gated by `can_edit?`, a new ApplicationController helper); it lives inside `turbo_frame#plants-results` so the Turbo Stream response updates every card. Location show page also has "Water all" + "Create a group from these plants".
  - **`PlantGroup` model** — custom, possibly cross-location collections. `PlantGroupsController` is standard CRUD (auth checklist like LocationsController) + `member post :water` (`water_all!`) + `collection post :seed_from_location` (creates a group named after a location, attaching its plants). `PlantGroup#apply_schedule_to_members!` pushes the group's min/max freq onto members (opt-in `apply_schedule` checkbox on the form). Reachable via a "👪 Groups" nav item.
- **Turbo Stream DRY:** `plants/_watered_streams.turbo_stream.erb` (locals `plant`, `watering`) holds the `replace_all "##{dom_id(plant)}"` (triple-rendered cards) + `replace dom_id(plant, :show)` pair. `quick_water`, `plant_groups/water`, and `locations/water_all` all render it (the bulk ones loop over `@watered`).
- **Plant form:** group membership is a checkbox block (`plant[plant_group_ids][]` with a leading hidden blank to allow clearing); `PlantsController#assign_plant_groups` filters ids to `current_project.plant_groups` (prevents IDOR), mirroring `assign_plant_recipes`.
- **Deferred (Phase B):** a dedicated "Groups" *display mode* on the plants index (parallel to location/recipe) was NOT built — a plant in multiple groups would render duplicate cards with the same `dom_id` in one visible container, breaking the `location_filter_controller.js` pagination/count logic. Manual-group watering is currently reached via the group show page. Also future: the 0/1/2 per-plant/per-group **tracking-level continuum** (default on Project, override on plant/group).

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

## Feature Flags & Onboarding

Five user-level boolean flags (`User::FEATURE_FLAGS`, columns default true) hide/show advanced UI per-user: `track_waterings` (watering history), `use_fertilizers` (recipes/sources/batches), `precise_measurements` (volume/units/TDS), `track_soil_moisture`, `has_aquarium` (Tanks section). Key facts:

- **One-time onboarding wizard** at `/onboarding` (OnboardingController, multi-step view driven by `onboarding_controller.js`); enforced by a global `before_action :require_onboarding` in ApplicationController that redirects any signed-in user with `onboarding_completed_at: nil`. Controllers that must work pre-onboarding (sessions, settings, auth flows, shared plants, transmit, etc.) use `skip_before_action :require_onboarding`. OnboardingController itself has `ensure_project` so it can seed sources/recipes into `current_project`.
- **Wizard steps:** (1) "Which do you have?" → `has_aquarium`; (2) "How do you water?" tap / fertilizer / distilled-RO → `use_fertilizers` enabled when fertilizer **or** distilled is chosen (it gates the whole sources/recipes feature, so distilled-only still needs it on); (2b) name fertilizers → each becomes a `RecipeSource` + a starter `Recipe`, distilled adds a "Distilled / RO Water" source (all via `find_or_create_by`); (3) add a first plant or tank (`next` param → `new_plant_path`/`new_tank_path`). `skip` completes onboarding with all five flags off.
- **`track_waterings` / `precise_measurements` / `track_soil_moisture` are NOT asked in onboarding** — the wizard writes them `false` and they **auto-enable on first use** via `User#enable_feature!(flag)` (idempotent `update_column`, raises on unknown flag):
  - `track_waterings` ← logging a detailed watering (`waterings#create`). Quick-water (`plants#quick_water`) stays ungated and does NOT opt in.
  - `precise_measurements` ← submitting a `volume` or `tds` on a watering (`waterings#create`/`#update`).
  - `track_soil_moisture` ← creating a soil moisture reading (`soil_moisture_readings#create`), or submitting pre/post moisture on a watering.
  - For these affordances to be reachable while off: `WateringsController` gate is `except: [:create, :new]`, `SoilMoistureReadingsController` gate is `except: [:new, :create]`, and the volume/TDS/moisture disclosures in `waterings/_form.html.erb` plus the detailed-watering / "Log Soil Moisture" links in `plants/show.html.erb` always render (no longer wrapped in `feature_enabled?`).
- **Flags editable any time** from the Settings page "Features" card (settings#update permits `*User::FEATURE_FLAGS`).
- **Views** check `feature_enabled?(:flag)` (ApplicationController helper; returns true when signed out). **Controllers** are gated with `require_track_waterings` / `require_use_fertilizers` / `require_has_aquarium` / `require_track_soil_moisture` filters (redirect to plants_path).
- The TDS block in `waterings/_form.html.erb` is outside the recipes conditional — fertilizers-off + precise-on users still get TDS.
- When `track_waterings` is off but `use_fertilizers` is on, the sidebar shows a Recipes nav item in place of Water (otherwise recipe pages would be unreachable).
- **Test fixtures**: users `one`/`two` have `onboarding_completed_at` set (required — otherwise every authenticated controller test redirects to onboarding); user `fresh` is non-onboarded for onboarding tests and owns `projects(:project_fresh)` (onboarding needs a project to seed into).

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
- **Plant cards (`_plant_row.html.erb`):** Urgency-tinted cards (`normal`/`scheduled`/`needs_water`) with a **watering-status spine** — a saturated `border-left` in the urgency hue (blue / green / amber); reads as **left = status, right = the full-height water button**. Structure: `.plant-card-graphic-col` (photo) | `.plant-card-body` (wraps `.plant-card-name` over `.plant-card-details`) | `.plant-card-water-wrap`. The title splits `plant.uid` into a monospaced `.plant-card-accession` tag ("#90") + `.plant-card-common-name` (rendered separately, NOT via `plant.label`). `.plant-card-details` holds the semibold watering-countdown line + `.plant-card-meta` (attribute lines in a **single-column** grid — each line show/hide-able and drag-reorderable via the card-fields menu).
- **Plant card responsive layout:** `.plant-cards` is a single-column list by default, a 2-col grid ≥1200px, 3-col ≥1550px (cards are narrow since attributes are single-column). At **≤500px** the card stacks into four full-width rows — **title / full-width photo hero / details box / water button** — via `.plant-card-body { display: contents }` (lifts the title out of the middle column) + flex `order`; the photo (`.plant-card-graphic img`) goes `height:auto` full-width (`max-height:70vh`), and title/details/button font sizes are scaled up to match it.
- **Quick water:** Water button is a `button_to` (POST) that creates a watering inline via Turbo Stream. Card updates to show "Watered!" + edit link (full-column `link_to`). Uses `aria-busy` CSS for optimistic feedback during request. The `<form>` has `padding: 0` and the `<button>` inside has the padding so the entire column is clickable. `.plant-card-water-col` has `min-width: 6rem` to prevent width changes when content swaps between states.
- **Triple-rendered cards:** Each plant card is rendered 3 times (once per display mode: watering, location, recipe). Only one mode is visible at a time (CSS `display: none`). All three share the same `dom_id`. **Turbo Stream actions must use `replace_all` (CSS selector via `targets:`) not `replace` (single ID via `target:`),** otherwise only the first DOM instance updates.
- **Header (collapsible search panel):** `header_extra` renders a `display:contents` wrapper (`data-controller="location-filter filter-collapse"`) holding: `.header-top-row` (flex/wrap) = `#headerSearch` (search form) + `.saved-searches-row`; then `.header-collapse-panel` > `.header-collapse-inner` = the location/recipe filter buttons (`.filter-row-content`) + `.sort-toggle-row` (sort/display-mode buttons + the **"Hide watered plants" checkbox**, `name=hide_scheduled`, linked to the search form via `form="plantSearchForm"`); plus a floating rectangular `.filter-collapse-btn` handle straddling the header's bottom edge. The panel is collapsed by default (see `filter_collapse_controller`).
  - **Saved searches hide with the panel:** `.saved-searches-row` (the saved-search chips + the "name this search" save form) is `display:none` while the panel is collapsed and shown only when expanded (`header:has(.filter-collapse-btn[aria-expanded="true"]) .saved-searches-row`), at all widths — so the chips don't wrap to a new line and clutter the minimized header. The hide targets the **row**, not the children, because the save form's visibility is set via a JS-managed **inline** `style.display` (`location_filter#updateSaveFormVisibility`) that would override a selector-based rule on the form itself; a `display:none` ancestor hides the subtree regardless, and the JS still governs the save form when the panel is expanded.
- **Counts toolbar:** `.plants-toolbar` sits at the **top of the results frame** (NOT the header). Shows a single line "Showing N Plants" + a " - Show All" link (= `clearSearch`; rendered when a search/filter/non-default-display/hide-scheduled is active) via `location_filter#updateResultsCount`. In multi-select mode it reads "Selected X out of N plants" instead. The "☑ Select" button is left-aligned in this toolbar, right after the counts. N is the client-side filtered/visible count.
- **Multi-select / bulk actions:** The "☑ Select" toggle (`plant_select_controller#toggleMode`) reveals per-card checkboxes + a bulk-action bar (Water selected / Create group / Add to group / Set location / Archive). In selection mode the **whole card toggles selection** (`plant_select#cardClick`) **except** the watering column (`.plant-card-water-wrap`) and the checkbox; the plant-show and location links are disabled via `.selection-mode { pointer-events: none }` so their clicks fall through to the card. Selection is keyed by plant id and synced across the triple-rendered cards. The per-card checkbox (`label.plant-card-select` in `_plant_row`) is **hidden by default via an inline `style="display: none;"`** (NOT a CSS class or the `hidden` attribute), toggled by `_showCheckboxes` — see the gotcha below. Every selection/mode change calls `_refreshCount()` → the sibling `location_filter#updateResultsCount` to keep the toolbar's "Selected X out of N" line current.
- **Card fields menu (⚙️):** A cog button floating in the **header's bottom-right corner** (`.card-fields-menu` lives in `header_extra`, positioned `absolute` relative to `<header>` and straddling its bottom edge like the collapse handle; `card_fields_controller`) opens a two-column dropdown: a **draggable example card preview** (left) + a **show/hide checklist** (right). Users toggle which attribute lines appear on plant cards and drag preview rows to reorder them. Both prefs persist per-device in localStorage (`plant-card-hidden-lines`, `plant-card-line-order`) and apply to every real card via a single injected `<style id="plant-card-line-toggles">` in `<head>` (`display:none !important` + grid `order` rules on `.plant-card .<line-class>`), so they survive display-mode switches, pagination, and Turbo Stream replaces. "Next watering" is a fixed headline (not reorderable); the 6 `.plant-card-meta` fields are. Since it lives outside `turbo-frame#plants-results`, the controller doesn't re-init on search.
- **Key Stimulus controller:** `location_filter_controller.js` handles filtering, pagination, display-mode switching, and the counts line

## Stimulus Controllers

| Controller | Purpose |
|-----------|---------|
| `location_filter_controller` | Plants index: client-side filtering (location/recipe), display-mode switching, pagination, and the counts line ("Showing N" / "Selected X out of N"). Runs as two instances coordinating across the header/frame boundary (see gotcha) |
| `filter_collapse_controller` | Plants index header: collapse/expand the search-options panel (filter buttons + sort + hide-watered checkbox). Toggles `.expanded` on `.header-collapse-panel` + `aria-expanded` on the floating `.filter-collapse-btn` handle; CSS animates `grid-template-rows: 0fr↔1fr`. Default collapsed; auto-collapses when `<main>` scrolls, re-expands at top |
| `collapsible_filters_controller` | Expand/collapse filter button rows (localStorage persistence) |
| `collapsible_group_controller` | Collapsible location/recipe groups (localStorage persistence) |
| `sidebar_controller` | Sidebar minimize/expand via hamburgerButton target, mobile auto-close, icon-rail mode, touch/swipe handling |
| `dropdown_controller` | Header user dropdown menu |
| `locale_popup_controller` | Sidebar locale switcher popup |
| `header_search_controller` | Debounced auto-submit for search |
| `card_fields_controller` | Plants index cog menu (⚙️, header bottom-right): show/hide plant-card attribute lines (checkboxes) + drag-reorder them on an example preview card (pointer events → mouse+touch). Enforces both prefs on every card via one injected `<style>` (`display:none` + grid `order`); persists to localStorage (`plant-card-hidden-lines`, `plant-card-line-order`) |
| `plant_select_controller` | Plants index multi-select: "Select" mode toggle, whole-card click-to-select (`cardClick`, skips the watering column), per-card checkbox reveal (inline `display`), selection keyed by plant id (synced across triple-rendered cards), select-all over filtered set, bulk water/archive/set-location/create-group/add-to-group via dynamically-built POST form. Calls the sibling `location-filter#updateResultsCount` (`_refreshCount`) to refresh the counts line |
| `plant_graphic_controller` | Graphic selection with live preview and auto-matching by name |
| `watering_recipe_controller` | Dynamic batch dropdown on recipe change, auto-fill TDS |
| `watering_moisture_controller` | Progressive disclosure of pre/post moisture fields |
| `nested_form_controller` | Add/remove rows for nested attributes (recipes) |
| `push_notification_controller` | Push device list: inline enable/disable toggle, "This Device" detection, test button state, global toggle sync |
| `notification_settings_controller` | Notification card: collapse/expand, frequency settings, dirty tracking, global enable/disable toggle, test button state |
| `dynamic_header_controller` | Scroll-driven header collapse on plant/watering show/edit pages. Attached to `<main>` via `content_for?(:header_extra)`, but only activates when `--header-expanded`/`--header-collapsed` CSS variables are defined (pages with `.header-plant-graphic`). Intercepts wheel/touch events to smoothly interpolate `--header-height`, `--graphic-opacity`, `--title-opacity` CSS custom properties. Content stays visually in place during collapse (no scrolling behind header). Only activates when content overflows; latches once started so collapse always completes fully. On mobile, tracks touch velocity and applies momentum animation on `touchend` so swipe gestures smoothly complete the header transition with deceleration (friction-based rAF loop). New touches cancel any in-progress momentum. No-ops on pages like plants index where `header_extra` is the search bar (no CSS variables defined). |

## Layout Architecture

- **Grid layout:** `"sidebar header" / "sidebar main"` — sidebar spans both rows
- **Context-aware header:** `display: grid` with single column; all children share same grid cell. Gradient color and title change per controller section (Plants=green, Waterings=blue, Tanks=teal, etc.) via `header_config` helper. `#headerTitle` is a direct child of `<header>`, truly centered independent of `#headerRight` (email/dropdown)
- **`header_config` keys:** `icon` (section icon), `title` (page-specific), `section_title` (generic section name for hamburger), `gradient_class`, `nav_path` (always a valid section index URL), `plant_graphic` (show pages only)
- **Sidebar structure:** Three sections top-to-bottom:
  1. `button.hamburgerToggle` — ☰ icon (absolutely positioned in 4rem box, never moves during animation) + section title (fades with opacity transitions)
  2. `a.sidebarNav` > `#logoContainer` — tall section icon (16rem expanded via `--logo-size`, header-height minimized), always links to section index
  3. `<nav>` — current section's sub-nav (`.indent`) at top, all sections vertically centered between `.fill` divs, locale switcher at bottom. Current section shown with `selected` class (also accessible via sidebarNav/logoContainer)
- **Sidebar states:** Minimized = icon rail (4rem wide, emoji-only nav labels, hamburger title hidden); expanded = full 18rem with text labels
- **FOUC prevention:** Inline `<script>` in `<head>` applies sidebar state before render; hamburger icon uses absolute positioning so it never shifts during sidebar width transitions; title uses opacity transitions to avoid flash
- **Mobile (≤600px):** Sidebar hidden when minimized; hamburger button fixed top-left; `a.sidebarNav` with `#logoContainer` remains visible (expands to full `--logo-size` when sidebar is open, compact at header-height when minimized)
- **Dynamic header (plant/watering pages):** When `.header-plant-graphic` is present, the header expands from `--header-collapsed` (`4.5rem`/`4rem` mobile) to `--header-expanded` (`14.5rem` both desktop and mobile) with a single-row grid. The `dynamic_header_controller` (attached to `<main>`) intercepts wheel/touch events and smoothly interpolates `--header-height`, `--graphic-opacity` (1→0), and `--title-opacity` (0→1) as CSS custom properties on `<body>`. During collapse, `preventDefault()` stops actual scrolling so content stays in place — normal scrolling only begins after full collapse. Re-expansion happens when the user scrolls back to `scrollTop=0`. The controller skips activation if content fits without scrolling, but once collapse begins it always completes fully (latched). The controller also skips activation on pages without `--header-expanded`/`--header-collapsed` CSS variables (e.g. plants index, which has `header_extra` for the search bar but no `.header-plant-graphic`). `#headerRight` uses `align-self: center` for vertical centering. Header uses `overflow: visible` (not `hidden`) so the user dropdown menu can extend below the header; `.header-plant-graphic` itself has `overflow: hidden` to clip during collapse. On mobile, the hamburger button spans the full `--header-height` for vertical centering.
- **Plant graphic banner (legacy):** On plant/watering show pages, `.plant-graphic-banner` renders in `section#primary` before yield; on plant edit, rendered inside `.settings-card` instead. Uses `max-width: var(--card-max-width)` (shared CSS variable with `.info-card-grid`). Prefer the header graphic approach (`content_for :header_extra`) over this legacy banner.
- **`--card-max-width: 650px`** CSS variable on body — shared by `.plant-graphic-banner`, `.info-card-grid:has(.details-section)`, and plants index search bar. Resets to `none` at ≤750px so content shrinks with the viewport.
- **Responsive overflow prevention:** `main` and `section#primary` both have `min-width: 0` to allow shrinking inside the body grid. All flex/grid children in the content chain (`.info-card-section`, `.watering-text`, `.water-icon-link`, `.info-row .value`) also need `min-width: 0` — without it, flex/grid items default to `min-width: auto` and refuse to shrink below their content width, causing horizontal overflow that `overflow-x: clip` cannot fix.
- **Breakpoints:** ≤600px (mobile: sidebar top-aligned, hamburger fixed), ≤750px (`--card-max-width` disabled, `.info-card-grid` single column), ≤900px landscape with ≤500px height (compact sidebar logo)
- **Plants index header:** A `display:contents` wrapper (in `header_extra`) promotes its children into the header grid (`minmax(0,1fr) auto`, `align-items: start`). Row 1: `.header-top-row` (col 1; flex/wrap holding `#headerSearch` + `.saved-searches-row`) and `#headerRight` (col 2). Row 2: `.header-collapse-panel` (col 1/-1, the collapsible search-options panel). `#headerTitle` is hidden; `#headerSearch` is `max-width: var(--card-max-width)`. The header has `padding-bottom` and `section#primary` has `padding-top` to reserve space for the floating `.filter-collapse-btn` handle (rectangular, ~`4rem×1.6rem`) that straddles the header/main border. A circular `.card-fields-menu` cog (⚙️) also floats on that bottom edge, at the **right corner**. The plant **counts live in the frame's `.plants-toolbar`**, not the header.
- **Nav icons:** Plants uses `autofauna_icon.png` with `.nav-icon` class (other sections still use emoji, to be migrated)

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
- `/locations/:id/water_all` - Bulk-water every non-archived plant in a location (Turbo Stream)
- `/plant_groups` - Manual plant groups (CRUD); `:id/water` bulk-waters members, `seed_from_location` creates a group from a location's plants
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
- **Required associations:** Sensors require `zone` and `sensor_type`, Plants require `project`. Tanks require only `project` — `location` is optional (`belongs_to :location, optional: true`), since onboarding can create a tank before any locations exist
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
- **Create/update tests** must include all required association params (e.g., `sensor_type_id` for sensors). `location_id` is optional for tanks
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

**Cloning production data locally:** `util/clone_production_db_to_local.sh` (env vars `AUTOFAUNA_SERVER`, `AUTOFAUNA_USER`; pass `-s` to also boot the dev server) dumps + restores the production DB, then `rsync`s the Active Storage files. Uploads use the **Disk** service rooted at `Rails.root.join("storage")` (a Capistrano `linked_dir` → `shared/storage/` on prod). The DB clone copies the `active_storage_blobs` rows (with their keys) but **not** the files, so the script rsyncs `shared/storage/` → local `storage/` to match. Variants regenerate on demand locally (needs libvips).

- **Targeted image sync (bandwidth saver):** set `AUTOFAUNA_SYNC_USER_EMAIL=<email>` to sync only that user's plant images instead of the whole storage tree. The script runs `util/list_user_storage_paths.rb` against the just-restored local DB to compute the Disk paths (`key[0..1]/key[2..3]/key`) for blobs attached to `user.plants` (originals only — variants regenerate locally), then passes them to `rsync --files-from`. No extra load on production. Unset → full sync (default).

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

- **Active Storage / plant images:** Plants have `has_one_attached :custom_image` (PlantGraphics concern). `display_graphic` returns a resized AS variant when an upload is attached, else the library asset-path string, else nil — a custom upload always wins over the library `graphic`. Views render via `display_graphic`/`has_graphic?` (not the old `graphic_path`/`graphic.present?`). Storage is the local Disk service; `storage` is in Capistrano `linked_dirs` so uploads survive deploys. **Requires libvips on every box that processes variants (dev + production server).**
- **`active_storage:install` fails with "Invalid DATABASE provided":** Rails' `railties:install:migrations` reads `ENV["DATABASE"]` as a multi-db *config name* (expects `primary`), but this app repurposes `DATABASE` as the literal db name (`.env` → `database.yml`). The values collide and the task raises. **Workaround:** copy the gem's migration directly instead of running the rake task — `cp "$(bundle show activestorage)/db/migrate/*_create_active_storage_tables.rb" db/migrate/<fresh-timestamp>_create_active_storage_tables.active_storage.rb`, then `bin/rails db:migrate`. Same caveat applies to any `*:install:migrations` task. (`DATABASE=primary` would satisfy the task but breaks `database.yml`, so don't.)
- **Newly-bundled gems require a server (and Sidekiq) restart:** A long-lived `bin/rails server` loads its gems once at boot; adding a gem to the bundle mid-session causes runtime `LoadError (cannot load such file -- <gem>)` (e.g. `image_processing` when generating AS variants, `ruby-vips` in `ActiveStorage::AnalyzeJob`) until you restart the server **and** any running Sidekiq worker. ERB/view changes reload without a restart; gem and SASS changes do not.
- **Flex/grid `min-width: 0` rule:** Any flex or grid child that should shrink below its content width needs `min-width: 0`. Without it, the default `min-width: auto` prevents shrinking and causes horizontal overflow. This applies throughout the layout chain: `main`, `section#primary`, `.info-card-section`, `.watering-text`, `.water-icon-link`, `.info-row .value`. When adding new flex/grid containers with variable-width content, always add `min-width: 0` to children that need to shrink.
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
- **Plant `has_many :waterings` has a default scope:** `has_many :waterings, -> { order 'waterings.watered_at' }` on Plant applies ascending order. This propagates through `has_many :waterings, through: :plants` on Project. Use `reorder` (not `order`) when you need a different sort on `current_project.waterings` — otherwise the association scope's ORDER BY takes precedence.
- **No `assigns` in tests:** The `rails-controller-testing` gem is not installed. Controller tests cannot use `assigns(:var)`. Instead, assert against the rendered response body (e.g., check marker strings appear in expected order).
- **Plant model N+1 risks:** Several Plant methods load the `waterings` collection (`first_watering`, `last_fertilized`, `suggested_watering_unit`, `calculate_watering_frequency`). The `last_watering` method uses `belongs_to :last_watering` (eager-loadable) with a fallback to `waterings.last`. The `graphic_path` method calls `self.class.available_graphics` which does `Dir.glob` on every call (not memoized).
- **Watering `after_save_commit` callback timing:** `update_last_watering` updates `plant.date_last_watering` and `plant.last_watering_id` via `after_save_commit`. When rendering a Turbo Stream response immediately after creating a watering, **do not rely on these fields being set** — the callback may not have committed by the time the template renders. Pass the new watering explicitly (e.g., `just_watered: @watering` local) instead of checking `plant.date_last_watering`.
- **`button_to` inside `<turbo-frame>`:** Forms inside a turbo-frame can still return Turbo Stream responses — the stream content type takes precedence over frame handling. Do NOT add `data: { turbo_frame: "_top" }` to break out of the frame for turbo stream responses; this causes Turbo Drive to process the response as a page-level navigation, which reverts the stream updates.
- **`button_to` and `<button>` color inheritance:** `<button>` elements have a browser default `color` (usually `buttontext`) that overrides CSS inheritance. When using `display: contents` on a `button[type="submit"]` inside a styled parent, add `color: inherit` to the button rule so SVGs with `fill="currentColor"` pick up the parent's color.
- **Plants index `turbo_frame_tag "plants-results"`:** The search form targets this frame, and all plant cards live inside it. Forms and links inside this frame that need turbo stream responses work without `_top`. Links that navigate away (e.g., to plant show/edit) DO need `data: { turbo_frame: "_top" }`.
- **Dual `location-filter` controller instances:** The plants index has two — the **outer** on the header's `display:contents` wrapper (owns the search input, the location/recipe filter buttons, and the saved-search form) and the **inner** inside `turbo-frame#plants-results` (owns the cards, groups, pagination, and the `.plants-toolbar` count targets). They coordinate via the `location-filter:apply` document event (carries `locations`, `recipes`, `currentPage`, `displayMode`) and `_crossTarget`/`_crossTargets` (which fall back to `document.querySelector`). Only the inner reconnects on frame reload; the outer persists. `updateResultsCount` runs only on the inner (the card owner) and writes the count line; in `selection-mode` it renders "Selected X out of N" by reading the sibling `plant-select` controller via `application.getControllerForElementAndIdentifier(this.element, "plant-select")` (both controllers share the frame wrapper element).
- **`display:contents` header wrapper — keep its HTML perfectly balanced:** The plants-index header content lives in a `<div style="display:contents" data-controller="location-filter filter-collapse">` inside `<header>`. A stray/mismatched tag *inside* it (e.g. an extra `</div>` in a filter block or partial) makes the browser close the wrapper early and **hoist trailing elements out of it** — they become siblings of the wrapper, outside the controllers' scope, so their Stimulus actions silently never bind (symptom: clicking does nothing, `aria-expanded` never flips, even though the controller is connected). `display:contents` doesn't change the DOM tree, so `btn.closest('[data-controller]')` still reveals the *real* parent — use it to debug. Verify nesting by `<div>`/`</div>` balance **per block**, not just the file overall.
- **CSS `grid-template-rows: 0fr↔1fr` collapse (header search panel):** `.header-collapse-panel` is `display:grid; grid-template-rows: 0fr`, animated to `1fr` (via the `.expanded` class or `header:has(.filter-collapse-btn[aria-expanded="true"])`); the inner `.header-collapse-inner` has `overflow:hidden; min-height:0`. **Do not put vertical padding on the collapsing element** — padding doesn't shrink with the `0fr` row, leaving a visible strip of content when collapsed (`overflow:hidden` clips children, not the element's own padding). Keep horizontal padding only on `.header-collapse-inner`; bottom spacing comes from the content inside it.
- **`form.button_to` display override:** `shared.sass` sets `form.button_to { display: inline-block }`. To override `display` on a `button_to` form inside a component, use a more specific selector (e.g. `.my-component form.button_to { display: flex }`) — the extra class raises specificity above the shared rule.
- **`aria-busy` loading state on `plants-results`:** Setting `aria-busy="true"` on `turbo-frame#plants-results` (manually before `requestSubmit`, then managed by Turbo during the request) triggers CSS that dims `.plant-cards` and `.pagination-controls`. The `_resetInstantly()` method on `location_filter_controller` performs immediate client-side reset (clear inputs, deactivate filter buttons, remove clear-search links) before the server round-trip.
- **CSS transition direction:** The `transition` property of the **destination** state determines animation duration. Placing `transition: opacity 0.4s` on the base element and `transition: opacity 0.1s` inside an `[aria-busy]` rule gives a fast fade-out (0.1s, destination is the busy state) and a slow fade-in (0.4s, destination is the normal state).
- **Nested route param names:** Routes nested inside `resources :plants do` (like `get 'water'`, `post 'quick_water'`) use `params[:plant_id]`, not `params[:id]`. The `set_plant` before_action uses `params[:id]`, so these actions must find the plant manually via `current_project.plants.find(params[:plant_id])` — same pattern as the existing `water` action.
- **`plants/_plant.html.erb` reads the `@plant` ivar, not a `plant` local:** the plant *show* card partial references `@plant` throughout (unlike `_plant_row.html.erb`, which uses the `plant` local). `render @plant` only works when `@plant` is set. Bulk watering (group/location) has no `@plant`, so `plants/_watered_streams.turbo_stream.erb` sets `@plant = plant` before the show-view `replace`. Any new context that renders the `_plant` show partial must set `@plant`.
- **Bulk/group watering shares `Plant#quick_water!(at:)`:** the carry-forward watering logic (copies last watering's volume/units/notes/recipe/batch/tds) lives on the model. `PlantsController#quick_water`, `PlantGroup#water_all!`, and `Location#water_all!` all call it. Group/location bulk-water Turbo Stream templates loop `@watered` and render `plants/_watered_streams` per plant (`replace_all` for the triple-rendered cards, `replace` for the show view — the latter a no-op on the index).
- **Default-hide an element with inline `style="display:none"`, not the `hidden` attribute or a CSS class, when stale compiled CSS is a risk:** The plant-card multi-select checkbox (`label.plant-card-select`) is hidden by default via an inline style, toggled by `plant_select_controller#_showCheckboxes`. We first tried a `.plant-card-select { display: none }` CSS rule and then the `hidden` attribute; both failed in dev because the running server was serving a **stale compiled stylesheet** from an earlier iteration of the feature that still had `.plant-card-select { display: flex }`. Cascade origin/specificity is why: an author class rule (`.plant-card-select`, even at equal specificity) beats the UA `[hidden]` rule, but an **inline style (specificity 1,0,0) beats any selector-based author rule** (barring `!important`). Inline style lives in server-rendered ERB (always fresh, no Sprockets recompile needed), so it's the bulletproof choice. **General lesson:** if a `display`/visibility CSS change "isn't taking effect" in dev, suspect stale assets — Sprockets live-compiles (no `public/assets` in dev) but the running `bin/rails server` process may not pick up SASS changes until restarted; ERB changes reload without a restart. Verify the true cascade by compiling the SASS (`SassC::Engine`) rather than trusting the source.
