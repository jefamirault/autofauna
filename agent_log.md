# Agent Log

Current session log. Previous logs archived in `agent_log/`.

---

## Plants Index: Multi-Select & Bulk Actions (planned)

Adding a selection mode to the plants index: a "Select" toggle reveals a checkbox on each
card + a bulk-action bar. Actions: **Water selected** (with optional fertilizer/amount
panel), **Create group**, **Add to existing group**, **Set location**, **Archive selected**.

Plan:
1. **Routes** — `plants` collection: `bulk_water`, `bulk_archive`, `bulk_set_location`.
   `plant_groups`: member `add_plants`, collection `create_from_selection`.
2. **`Plant#quick_water!`** gains `overrides:` keyword (present overrides win via
   `compact_blank`; carry-forward for blanks). Location/PlantGroup callers unaffected.
3. **`PlantsController`** — `bulk_water` (turbo_stream, in-place via `_watered_streams`),
   `bulk_archive`/`bulk_set_location` (POST→redirect, carry q/filters in `forward_params`).
   `watering_overrides` scopes recipe/batch to project (IDOR). `@all_locations`/`@all_groups`
   added to `index` for the action-bar dropdowns.
4. **`PlantGroupsController`** — `create_from_selection` (new group→edit), `add_plants`
   (member, add to existing). Mirrors `seed_from_location`.
5. **Views** — `bulk_water.turbo_stream.erb`; checkbox in `_plant_row`; Select toggle +
   sticky action bar + watering-details panel (reuses `watering-recipe` controller) in
   `index.html.erb`.
6. **Stimulus** — new `plant_select_controller.js` (selection state keyed by plant id,
   syncs triple-rendered checkboxes, select-all over filtered set, dynamic-form submit).
7. **Styles** (`plants.sass`) + **i18n** (`en.yml`: `plants.bulk.*`, `plant_groups.*`).

Constraints honored: triple-rendered cards (key off plant id, sync 3 copies), client-side
filter/pagination (select-all spans all pages of filtered set), dual `location-filter`
instances (new controller on inner frame element only). Editor-gated via `can_edit?`.

**Implemented.** Files changed: `config/routes.rb`, `app/models/plant.rb`,
`app/controllers/plants_controller.rb`, `app/controllers/plant_groups_controller.rb`,
`app/views/plants/{index.html.erb,_plant_row.html.erb,bulk_water.turbo_stream.erb}`,
`app/javascript/controllers/plant_select_controller.js`,
`app/assets/stylesheets/plants.sass`, `config/locales/en.yml`. Tests added to
`plants_controller_test.rb` (bulk_water turbo/override/carry-forward/recipe-IDOR/archive/
set_location/cross-project/empty) and `plant_groups_controller_test.rb`
(create_from_selection + add_plants, each with IDOR case).

Notes:
- The Stimulus controller submits a detached `<form>` via `requestSubmit()` so Turbo handles
  it (stream for water, redirect for the rest). CSRF token from `form_authenticity_token`.
- `units` select gets a leading blank "— keep —" option so an untouched units field doesn't
  override carry-forward (everything else is blank by default).
- TDS field is rendered hidden when fertilizers-on + precise-off so `watering-recipe`'s
  `batchChanged` auto-fill target always exists (avoids a JS error in that flag combo).
- No migration required.

Verified: `ruby -c` (all changed .rb), `YAML.load_file` (en.yml), ERB compile (all changed
templates), `node --check` (new JS) — all pass.

**User action:** run `bin/rails test test/controllers/plants_controller_test.rb test/controllers/plant_groups_controller_test.rb`
(and ideally the full suite), then smoke-test `/plants` per the plan's verification section.

---

## 2026-03-20: 1-Click Watering on Plants Index

**What:** Converted the water button on plant cards from a navigation link (GET → new watering form) to an inline POST action that creates a watering immediately and updates the card via Turbo Stream.

**Changes:**
- `config/routes.rb` — Added `post 'quick_water'` to plants resource
- `app/controllers/plants_controller.rb` — Added `quick_water` action: creates watering with carried-forward defaults from last watering, responds with turbo_stream or HTML redirect
- `app/views/plants/quick_water.turbo_stream.erb` — New template that replaces the plant card via `turbo_stream.replace`
- `app/views/plants/_plant_row.html.erb` — Collapsed "has history" and "no history" water button cases into a single `button_to` for quick_water; "watered today" case unchanged (links to edit)
- `app/assets/stylesheets/plants.sass` — Added `display: contents` on submit button inside `.plant-card-water-col` so form handles layout
- `test/controllers/plants_controller_test.rb` — 4 new tests: turbo stream response, carry-forward, no history, HTML fallback
- `test/controllers/authorization_test.rb` — 1 new test: cross-project IDOR protection

---

## 2026-03-21: Sprint 0.9.0 Kickoff

**What:** Launched milestone 0.9.0 sprint with 4 parallel workers on separate branches.

**Worker Assignments:**
| Worker | Branch | Issue | Scope |
|--------|--------|-------|-------|
| 1 | `sprint/0-9-0/plant-management` | #77 Dynamic Plants Index | Update needs-water count after quick watering |
| 2 | `sprint/0-9-0/ux-ui` | #76 Dynamic Header | Scroll-collapsing header with plant graphic |
| 3 | `sprint/0-9-0/localization` | #79 Spanish Localization | Fix 9 translation errors in es.yml |
| 4 | `sprint/0-9-0/weather` | #78 Weather Locations | Multi-location support with DB persistence |

**Actions taken:**
- Reviewed all 4 milestone issues and explored relevant code
- Posted detailed implementation guidance as comments on each issue
- Identified potential conflict: Worker 4 (weather) adds locale keys to en.yml/es.yml, Worker 3 (localization) fixes es.yml — coordinated scope boundaries to avoid overlap

**Sprint progress (second session):**
- Issues #76 and #77 already fixed and merged to main from previous session — closed both issues
- Issue #79: Previous fix on main, but branch `sprint/0-9-0/localization` has additional unmerged fixes (gender agreement, typos, i18n of hardcoded "Number" label) — created PR #80
- Issue #78 (Weather): Guidance posted, worker running in tmux, no commits yet — awaiting implementation
- 6 claude panes active in `claude-sprint` tmux session

**Sprint 0.9.0 Complete:**
- PR #80 (localization fixes) merged
- PR #81 (weather multi-location support) merged
- All 4 milestone issues (#76, #77, #78, #79) closed

---

## 2026-03-22: Sprint 0.9.1 Kickoff

**What:** Launched milestone 0.9.1 sprint with 2 parallel workers.

**Worker Assignments:**
| Worker | Branch | Issue | Scope |
|--------|--------|-------|-------|
| 1 | `sprint/0-9-1/ux-ui` | #82 | Smooth mobile touch header collapse/expand with momentum |
| 2 | `sprint/0-9-1/navigation` | #83 | Keep all nav links visible in sidebar (remove `unless` guards) |

**Actions taken:**
- Reviewed both milestone issues and analyzed relevant source code
- Posted detailed implementation guidance on issue #82 (touch momentum/inertia for dynamic header)
- Posted detailed implementation guidance on issue #83 (always-visible nav links with selected state)
- No file conflicts between workers — #82 touches only JS, #83 touches only ERB/helpers/CSS

**Worker results:**
- Worker 1 (branch `sprint/0-9-1/ux-ui`): Implemented momentum scrolling with velocity tracking, friction-based rAF loop on touchend, and cancel-on-new-touch — PR #84
- Worker 2 (branch `sprint/0-9-1/navigation`): Removed all `unless` guards from nav items, all sections always visible, current section gets `selected` class — PR #85
- Both branches also updated CLAUDE.md documentation (non-overlapping sections, no conflict)

**Sprint 0.9.1 Complete:**
- PR #84 (smooth mobile header) merged
- PR #85 (sidebar navigation) merged
- All milestone issues (#82, #83) closed

---

## 2026-04-24: Sprint v0.9.2 — Worker 3 — Tank Management

**Issues:** #44 (water change log), #45 (feeding instructions), #46 (equipment maintenance logs)

**Plan:**
- Migrations: add water_change schedule to tanks; create water_changes, feeding_instructions, equipment, maintenance_logs tables
- Models: WaterChange, FeedingInstruction, Equipment, MaintenanceLog; Tank model updated with associations
- Controllers: WaterChangesController, FeedingInstructionsController, EquipmentController, MaintenanceLogsController (all nested under tanks)
- Routes: nested resources under tanks
- Views: standard CRUD forms; tank show updated with new sections
- Tests: controller tests; fixtures for water_changes only (equipment/feeding_instructions load before tanks alphabetically)

---

## 2026-03-22: Sprint 0.9.1 (Round 2) Kickoff

**What:** Launched milestone 0.9.1 sprint with 2 parallel workers on new issues.

**Worker Assignments:**
| Worker | Branch | Issues | Scope |
|--------|--------|--------|-------|
| 1 | `sprint/0-9-1/plant-management` | #88 | TDS field collapsible behind "Add TDS" button |
| 2 | `sprint/0-9-1/ux-ui` | #87, #86 | Mini plant graphic in collapsed header + toast flash notifications + floating guest banner |

**Actions taken:**
- Reviewed all 3 milestone issues and explored relevant code (watering form, header layout, flash/guest banner)
- Posted detailed implementation guidance on issue #88 (TDS toggle — follows existing moisture field pattern)
- Posted detailed implementation guidance on issue #87 (mini plant graphic in collapsed header)
- Posted detailed implementation guidance on issue #86 (toast notifications + floating guest banner)
- No file conflicts between workers — Worker 1 touches watering form/recipe controller only, Worker 2 touches layout/flash/header CSS

**Worker results:**
- Worker 1 (branch `sprint/0-9-1/plant-management`): Implemented collapsible TDS field with toggle/hide/show methods, auto-reveal on batch selection — PR #89
- Worker 2 (branch `sprint/0-9-1/ux-ui`): Inline mini graphic in collapsed header via `header_config`, CSS-only toast flash notifications, floating guest banner — PR #90
- Revision: moved "Remove TDS" button inline with the TDS input field

**Sprint 0.9.1 (Round 2) Complete:**
- PR #89 (collapsible TDS field) merged
- PR #90 (mini header graphic + toast flash + floating guest banner) merged
- All milestone issues (#86, #87, #88) closed
- Worktrees and branches cleaned up

---

## 2026-04-24: Sprint 0.9.2 — Issues #71 and #21 (Worker 4, branch sprint/v0-9-2/ux-ui)

### Issue #71: Locale switcher + email dropdown styles

- Locale button now always shows current locale flag (🇺🇸/🇲🇽) — no longer shows globe icon
- Locale dropdown shows ALL options (English and Español) with flags; selected locale is highlighted
- `locale_popup_controller.js` simplified — flag display handled server-side
- Email button (`#headerEmail`) gains a `▾` chevron on the right using flex layout
- Logout button gets 🚪 icon for consistency with other dropdown items

### Issue #21: Saved Searches

- **Migration** `20260424130000_create_saved_searches.rb` — new `saved_searches` table
- **Model** `SavedSearch` with user/project associations and name/query_term validations
- **Controller** `SavedSearchesController` — create and destroy actions (Turbo Stream responses)
- **Route** `resources :saved_searches, only: [:create, :destroy]`
- **Plants index** — saved searches row at top of `#search-options`: chips for each saved search (click to apply, ✕ to delete) + inline save form when a search term is active
- **CSS** in `plants.sass` — pill-style chips, inline save form, auto-hide empty row via CSS `:has()`
- **Note:** Migration must be run: `bin/rails db:migrate`

---

## 2026-06-12: User Onboarding Flow + Feature Preference Flags

### Plan (approved)

Add five user-level boolean feature flags (`track_waterings`, `use_fertilizers`, `precise_measurements`, `track_soil_moisture`, `has_aquarium`), all defaulting to true, plus `onboarding_completed_at` timestamp on users. A one-time onboarding questionnaire (shown to everyone, including existing users, on next login) sets the flags via friendly questions; flags are editable any time from a new "Features" card on the Settings page. Flags hide/show advanced UI per-user (nav items, recipe/TDS/volume/moisture fields and displays, tanks section); data is never deleted. Quick-water always works regardless of flags (`waterings#create` stays ungated).

Key pieces:
- Migration: 5 boolean flags (default true, null false) + `onboarding_completed_at` datetime
- `User::FEATURE_FLAGS`, `onboarding_completed?`, `complete_onboarding!`
- `ApplicationController`: `feature_enabled?` helper, `require_onboarding` global before_action (skip-listed on onboarding/sessions/settings/auth/shared/transmit controllers), `require_*` gating filters
- New `OnboardingController` (show/update/skip) + routes + view
- Controller gating: waterings (except create), recipes/sources/batches, tanks + water_tests/water_changes/feeding_instructions/equipment/maintenance_logs, soil_moisture_readings
- View conditionals across layout nav, plants index/cards/forms/timeline, watering forms/show
- Nav gap fix: when waterings hidden but fertilizers on, show a Recipes nav item
- TDS block hoisted out of recipes conditional in waterings/_form so fertilizers-off + measurements-on keeps TDS
- Fixtures: backfill `onboarding_completed_at` on users one/two (prevents breaking all controller tests); new `fresh` fixture
- Tests: onboarding_controller_test.rb + feature_flags_test.rb
- i18n: en + es keys for onboarding and settings features card

### Implementation (complete)

- **Migration** `20260612000001_add_feature_flags_and_onboarding_to_users.rb` — 5 boolean flags (default true, null false) + `onboarding_completed_at` datetime. **User must run `bin/rails db:migrate`.**
- **User model** — `FEATURE_FLAGS` constant, `onboarding_completed?`, `complete_onboarding!`
- **ApplicationController** — `feature_enabled?(flag)` helper (true when signed out), global `before_action :require_onboarding`, four `require_*` gating filters
- **Skip list** (`skip_before_action :require_onboarding`): onboarding, sessions, settings, push_subscriptions, registrations, guests, guest_conversions, google_auth, passwords, password_resets, shared_plants, sensor_readings (transmit only), static, errors
- **OnboardingController** (show/update/skip) + routes (`GET/PATCH /onboarding`, `POST /onboarding/skip`) + `onboarding/show.html.erb` (settings-card, 5 friendly questions, Skip button); `header_config` case added
- **Controller gating**: waterings (`except: [:create]` — quick water keeps working), recipes/recipe_sources/recipe_batches (`require_use_fertilizers`), tanks/water_tests/water_changes/feeding_instructions/equipment/maintenance_logs (`require_has_aquarium`), soil_moisture_readings (`require_track_soil_moisture`; also fixed its missing authenticate/ensure_project)
- **View conditionals**: layout nav (recipes sub-nav, Water item — replaced by Recipes item when waterings off but fertilizers on, Tanks item), plants index (recipe filters/groups skipped server-side, display mode forced off "recipe"), plant cards/show/timeline/form, inline + full watering forms (TDS hoisted out of the recipes block so fertilizers-off + precise-on keeps TDS), watering show partial
- **Settings** — new "Features" card; `notification_params` → `settings_params` (+flags); generic save notices
- **i18n** — `onboarding.*` and `settings.*` keys in en.yml + es.yml
- **Fixtures** — users one/two get `onboarding_completed_at` (prevents global test breakage); new `fresh` user
- **Tests** — `onboarding_controller_test.rb` (8 tests), `feature_flags_test.rb` (9 tests)
- Note: guest merge keeps the target account's flags/onboarding state; a guest's onboarding answers are discarded when merging into an existing account

---

## 2026-06-18: Onboarding Redesign — Multi-Step Wizard + Enable-on-First-Use Flags

**Why:** The original onboarding asked five raw yes/no questions, one per feature flag, exposing internal feature names and demanding too much up front. Replace it with a friendlier wizard that asks only what the user *has* and *uses*, seeds real water-source/recipe data, and defers granular tracking preferences until those features are actually used.

**Plan (approved):**
- **Wizard flow (single client-side multi-step form):**
  1. "Which do you have?" — plants / fish-aquarium
  2. "How do you water?" — tap/hose / fertilizer / distilled-RO (tap-only ⇒ no sources, recipe features hidden)
  3. Fertilizer detail (only if checked) — name fertilizers → each becomes a RecipeSource + starter Recipe; distilled/RO ⇒ a source
  4. Final — add a first plant or tank
- **Flags:** `has_aquarium` ← page 1; `use_fertilizers` ← fertilizer OR distilled. `track_waterings`/`precise_measurements`/`track_soil_moisture` dropped from onboarding, default off, auto-enable on first use via new idempotent `User#enable_feature!`. No new flag for "has plants" (plants always visible; checkbox only drives final add-plant-vs-tank redirect).
- **Enable-on-first-use:** relax `require_track_waterings` (except create+new) and `require_track_soil_moisture` (except new+create) so entry affordances are reachable while off; flip flags in waterings/soil-moisture create/update when the user enters volume/TDS, logs moisture, or logs a detailed watering. Quick-water stays ungated and does NOT opt in. Always-visible disclosures in `waterings/_form` + plant show.
- **No migration** — columns already exist; defaults stay true so existing users/fixtures unaffected; wizard writes the three deferred flags false explicitly.
- **Files:** user.rb, onboarding_controller.rb, waterings_controller.rb, soil_moisture_readings_controller.rb, onboarding/show.html.erb, new onboarding_controller.js, waterings/_form.html.erb, plants/show.html.erb, en.yml/es.yml, onboarding/feature-flags/user tests, CLAUDE.md.

### Implementation (complete)

- **User model** — `enable_feature!(flag)` (idempotent `update_column`, raises on unknown flag)
- **OnboardingController** — rewritten: reads `has_aquarium` + water-method checkboxes + `fertilizers[]` + `next`; sets flags (`use_fertilizers = fertilizer || distilled`; three tracking flags false); `seed_water_sources!` creates a "Distilled / RO Water" source and a source+starter-recipe per fertilizer (`find_or_create_by`); redirects to new plant/tank/plants. `ensure_project` added. `skip` now writes all flags false.
- **Wizard view** `onboarding/show.html.erb` — single multi-step form (have / how-water / fertilizer-names / finish), `check_box_tag`/`text_field_tag`, final submit buttons carry `name="next"`. New `onboarding_controller.js` (step nav, conditional fertilizer step, dynamic fertilizer rows, tank-option visibility). Wizard styles in `shared.sass`.
- **First-use triggers** — waterings: gate `except: [:create, :new]`, `create` enables `track_waterings` + `enable_features_from_watering_params` (volume/tds→precise, moisture→soil), `update` runs the same helper. soil_moisture: gate `except: [:new, :create]`, `create` enables `track_soil_moisture`. Form/show affordances always render (removed `feature_enabled?` wrappers around volume/TDS/moisture and the detailed-watering/soil-moisture links).
- **i18n** — `onboarding.*` rewritten (have/water/fertilizers/finish + next/back) in en.yml + es.yml; obsolete `question_*`/`hint_*` removed.
- **Fixtures** — `projects(:project_fresh)` owned by `fresh` (onboarding needs a project to seed into).
- **Tests** — `onboarding_controller_test.rb` rewritten (tap-only / fertilizer / distilled / aquarium-tank / plant / skip / guards); `feature_flags_test.rb` updated for relaxed gates + 3 first-use enable tests; `user_test.rb` covers `enable_feature!`.
- **Docs** — CLAUDE.md "Feature Flags & Onboarding" rewritten.
- **User action:** no migration needed (flag columns already exist). Run: `bin/rails test test/controllers/onboarding_controller_test.rb test/controllers/feature_flags_test.rb test/models/user_test.rb`

- **Verification fix:** `boolean_param` coerces with `!!` — `ActiveModel::Type::Boolean#cast(nil)` returns nil, which violated the NOT NULL flag columns. All 28 tests (onboarding + feature flags + user) pass.

## Onboarding fertilizer step — selectable list instead of free-text only

- **View** (`app/views/onboarding/show.html.erb`): step 2b now shows a checklist of common fertilizers (Miracle-Gro and "General Hydroponics (Flora series)" checked by default; Fox Farm, Osmocote, Jack's / J.R. Peters, Dyna-Gro, Espoma, Schultz). Checkboxes submit `fertilizers[]` by name. A collapsible "Other" disclosure (`onboarding-other-entry`) holds the original manual text-input rows + "Add another" — hidden by default, not required to proceed.
- **JS** (`onboarding_controller.js`): added `otherEntry`/`otherToggle` targets and `toggleOther()` action (reveals manual rows, sets `aria-expanded`, focuses first input). `addFertilizer`/`removeFertilizer` unchanged (rows container untouched).
- **Backend unchanged**: `seed_water_sources!` already strips/rejects-blank/uniqs `fertilizers[]`, so checkbox names + manual entries merge cleanly.
- **i18n**: added `onboarding.fertilizers.other` (en/es); reworded `intro` to "Pick the fertilizers you use…".
- **CSS** (`shared.sass`): spacing for `.onboarding-fertilizer-options`, `.onboarding-other-toggle`, `.onboarding-other-entry`.

## Tanks — location now optional

- **Model** (`app/models/tank.rb`): `belongs_to :location, optional: true`. Onboarding can create a tank before any locations exist.
- **DB**: no migration needed — `tanks.location_id` was already nullable.
- **Views**: `tanks/show.html.erb` Location row now renders `@tank.location || '—'`. `_tank.html.erb` already guarded with `if tank.location`. Form already used a blank `prompt:` so no change.
- **Docs**: CLAUDE.md "Required associations" + create/update test notes updated (location no longer required for tanks).

## Onboarding: "Don't water with fertilizer" option (2026-06-20)

Added a mutually-exclusive first option to the "Which fertilizers do you use?" step (step 2b).

- **Locale** (`config/locales/en.yml`, `es.yml`): new `onboarding.fertilizers.none` string.
- **View** (`app/views/onboarding/show.html.erb`): new `no_fertilizer` checkbox as the first option in `.onboarding-fertilizer-options` (target `noFertilizer`, action `noFertilizerToggled`). Each common-fertilizer checkbox gets target `fertilizerOption` + action `fertilizerSelected`; the manual "Other" text input gets `input->onboarding#fertilizerSelected`.
- **JS** (`app/javascript/controllers/onboarding_controller.js`): `noFertilizerToggled` clears all fertilizer checkboxes and manual-entry inputs when "none" is checked; `fertilizerSelected` unchecks "none" when any real fertilizer is selected (checkbox or non-empty text). The `no_fertilizer` param is ignored by the controller, so seeding logic is unaffected.

## Plant Groups + Group Watering (Phase 1 of tracking-level vision) — 2026-06-24

**Why:** Tracking effort should scale with time/season and vary per-plant and per-group (water all Living-Room plants with one click; reserve detail for overwatering-prone succulents). Full vision is a 0/1/2 tracking-level continuum (later phase). This phase builds **groups + group watering first**.

**Plan (approved):**
- **Groups = both:** Locations act as implicit groups (group-water a location's plants, no new object) AND a dedicated `PlantGroup` model for custom/cross-location collections, seedable from a location. Eventual default tracking level will live on Project (per-project) — schema groundwork only, not built this phase.
- **Data:** new `plant_groups` (name, color hex-validated, project_id, optional min/max_watering_freq) + `plant_group_memberships` join (plant ↔ plant_group many-to-many, unique index).
- **Models:** `PlantGroup` (`water_all!`, `apply_schedule_to_members!`, color validation/`hex_color` copied from Location); extract `Plant#quick_water!(at:)` (carry-forward attrs + `waterings.create!`) from `PlantsController#quick_water`; `Location#water_all!`.
- **Controllers/routes:** `resources :plant_groups` + `member { post :water }` + `collection { post :seed_from_location }`; `member { post :water_all }` on `resources :locations`. `PlantGroupsController` (auth checklist like LocationsController). `quick_water` delegates to `Plant#quick_water!`.
- **Turbo Stream DRY:** extract `plants/_watered_streams.turbo_stream.erb` (replace_all card + replace show); reuse in quick_water, plant_groups/water, locations/water_all (loop over `@watered`).
- **UI:** plant_groups management pages; "Groups" checkbox on plant form; new "Groups" display mode + filters + "💧 Water all" buttons on plants index (location & group headers, inside turbo-frame); "Water all"/"Create group from these plants" on locations; "Groups" nav item.
- **i18n:** `plant_groups.*` + `plants.index.display.group` (en + es).
- **Tests:** plant_group model, `quick_water!`, plant_groups controller (CRUD/water/seed/authorization), locations#water_all; fixtures `plant_groups.yml` + `plant_group_memberships.yml` (+ p2 variant).
- **Docs:** CLAUDE.md domain model + Plant Groups subsection.

### Implementation (complete — pending user migrate + test run)

- **Migration** `20260624000001_create_plant_groups.rb`: `plant_groups` (name, color, project ref, min/max_watering_freq) + `plant_group_memberships` (plant/plant_group refs, unique index).
- **Models:** `PlantGroup` (associations, color validation/`hex_color`/`watering_frequency_text`, `water_all!`, `apply_schedule_to_members!`), `PlantGroupMembership`; `Plant#quick_water!(at:)` extracted from controller + `has_many :plant_groups`; `Location#water_all!`; `Project has_many :plant_groups`.
- **Controllers/routes:** `resources :plant_groups` (+ member `water`, collection `seed_from_location`), `member :water_all` on locations. New `PlantGroupsController`. `PlantsController#quick_water` delegates to `quick_water!`; `assign_plant_groups` (scoped) added to create/update; `plant[plant_group_ids]` synced. `LocationsController#water_all`. New `can_edit?` helper in ApplicationController.
- **Views:** `plant_groups/` index/new/edit/show/_form/_plant_group; `_watered_streams.turbo_stream.erb` partial reused by quick_water + plant_groups/water + locations/water_all; "💧 Water all" button on plants-index location headers; "Water all" + "Create group from these plants" on location show; "👪 Groups" checkboxes on plant form; "Groups" nav item (sub-nav + main).
- **CSS:** `.group-watering-bar`, `.group-water-all-btn`, `.plant-group-members` in shared.sass.
- **i18n:** `plant_groups.*` + `plants.index.water_all` (en + es).
- **Tests:** `plant_group_test.rb` (8), `plant_groups_controller_test.rb` (CRUD/water/turbo/seed/apply_schedule), `plant_test.rb` (+2 quick_water!), `authorization_test.rb` (+6 plant_group/location isolation), `locations_controller_test.rb` (+1 water_all). Fixtures `plant_groups.yml` + `plant_group_memberships.yml` (+ p2 variant).
- **Scope refinement (flagged):** deferred the separate plants-index "Groups display mode" — many-to-many membership would duplicate `dom_id`s in one container and break the 796-line `location_filter_controller.js` pagination/count logic. Location-header water-all (the headline "all Living-Room plants watered" UX) + group show-page watering deliver the value now.
- Verified: `ruby -c` on all changed .rb, YAML parse on locales/fixtures, ERB compile on all new/changed templates — all pass.
- **User action:** run `bin/rails db:migrate`, then `bin/rails test test/models/plant_group_test.rb test/models/plant_test.rb test/controllers/plant_groups_controller_test.rb test/controllers/locations_controller_test.rb test/controllers/authorization_test.rb`.

**Verified (migration + 54 tests green).** Post-test fix: `plants/_plant.html.erb` (show card) reads the `@plant` ivar, which bulk watering doesn't set — `_watered_streams.turbo_stream.erb` now sets `@plant = plant` before the show render so group/location watering renders without error (the show-view replace is a harmless no-op on the index). Also switched a no-op-schedule assertion to `assert_nil`.

---

## Plants Index — move counts + search options into the header

**Goal:** Consolidate the plants-index search/sort UI into the dark-green header. The `header.header-plants` now grows vertically to hold the plant counts plus the search options (saved searches, sort, select) and the location/recipe filter buttons. Per user decision: the **counts stay visible**; saved searches + sort + select + filter buttons collapse together (▲ toggle, default collapsed, via `filter-collapse` controller).

**Views (`app/views/plants/index.html.erb`):**
- Moved `.plants-count-headers` and `#search-options` (saved-searches row, sort row, select row) out of `turbo-frame#plants-results` and into the `content_for :header_extra` block, inside the existing outer `location-filter` wrapper.
- Added `data-location-filter-display-mode-value` / `-search-term-value` to the outer wrapper so the header instance has correct state for sort + save-form logic.
- New collapsible wrapper `.header-collapse-panel` (`data-filter-collapse-target="filterRow"`) wraps `#search-options` + `.filter-row-content`. The old `.filter-row` div is gone. The ▲ toggle is now always rendered.
- Select button: `data-action` changed from `plant-select#toggleMode` to `location-filter#toggleSelectMode` (it's now outside the plant-select element); dropped its `modeBtn` target.

**JS — dual-instance coordination (header = outer, frame = inner):**
- `location_filter_controller.js`: `_dispatchApply` now carries `displayMode`; the inner `location-filter:apply` listener applies display-mode switches (`updateDisplayMode`). `switchDisplayMode` dispatches to the inner instance (sort row lives in the header, cards live in the frame). `updateResultsCount` is guarded to the card-owning (inner) instance and writes counts via `_crossTarget` to the header's count elements. Added `toggleSelectMode()` (relays a `plant-select:toggle-mode` document event) and `_syncSaveForm()` (keeps the header save form's hidden `query_term` fresh after a frame reload, called from `connect`).
- `plant_select_controller.js`: listens for `plant-select:toggle-mode` (added `disconnect` to remove it); `_modeBtn()` helper finds the header's `.select-toggle-btn` cross-instance; resets the button to inactive on (re)connect.

**CSS:**
- `layout.sass` (`body:has(main.plants.index) header`): header grid is now 3 rows; `.plants-count-headers` (row 2) and `.header-collapse-panel` (row 3) span full width. Added dark-header overrides (white text/pills) for counts, sort/select `.display-toggle-btn` (active = white bg + `--section-color-start` text), saved-search chips, and the save-search input/button.
- `plants.sass`: removed the now-unused `.filter-row` rule (replaced by `.header-collapse-panel`, whose collapse styling lives in the header scope).

**Checks:** ERB block balance 0; layout/plants SASS compile; both JS controllers `node --check` clean. **Not yet run in a browser** — needs visual verification on the dark-green background (desktop + mobile), and a functional pass on sort switching, filtering, counts, saved-search save/load, clear-search, and select mode.

### Header layout refinement — counts/saved-searches up top, toggle to the bottom

- **"Show watered plants" toggle** moved out of the search form to a new bottom row of the header (grid-row 3, always visible, below the collapse panel / filter buttons). It now lives outside the search `<form>`, so it's associated via the HTML `form="plantSearchForm"` attribute (the search form got an explicit id via `search_form_for ... html: { id:, data: }`). `toggleHideScheduled` now uses `checkbox.form` instead of `closest('form')`.
- **Counts** + **saved searches** moved into a new `.header-top-row` flex container alongside `#headerSearch` (grid-row 1). Search bar grows (capped at `--card-max-width`); counts sit next to it; saved searches follow and wrap to the next line when the row runs out of width (`flex-wrap`). Counts restyled compact (stacked h1/h2, smaller fonts).
- Collapse panel is now grid-row 2; `#search-options` no longer contains the saved-searches row (just sort + select).
- Checks: ERB depth 0, layout/plants SASS compile, both controllers `node --check` clean. Still needs browser verification.

### Fix: collapse toggle didn't expand the panel

The `▲` handle fired `toggle()` (aria-expanded flipped) but the panel never visually expanded. Root cause: `filter_collapse_controller` animated the panel by reading `scrollHeight` and setting an explicit `height` — unreliable for a grid item promoted via a `display:contents` wrapper. Replaced it with a robust CSS-only collapse:
- Controller now just toggles an `.expanded` class (+ `aria-expanded`); no height measurement. Auto-collapse-on-scroll behavior preserved.
- `.header-collapse-panel` uses `display:grid; grid-template-rows: 0fr` → `1fr` (on `.expanded`), animated via `transition: grid-template-rows`. Content wrapped in `.header-collapse-inner` (`overflow:hidden; min-height:0`) so it clips cleanly to zero (also removes any padding "strip"). Collapsed by default in pure CSS, so no FOUC.

Checks: ERB depth 0, div balance 0, layout.sass compiles, controller `node --check` clean. Needs a browser confirm (no headless browser available here).

### Fix (follow-up): make collapse work regardless of cached controller build

Panel still wasn't expanding — most likely the browser was running the previous controller build (which set an inline pixel `height` that fights the new grid collapse). Made the CSS robust to that:
- Expansion is now driven by `header:has(.filter-collapse-btn[aria-expanded="true"]) .header-collapse-panel` (aria-expanded is set by every controller build), in addition to the `.expanded` class.
- Added `height: auto !important` on the panel to neutralize any stale inline height, so visible height is controlled solely by the `grid-template-rows: 0fr↔1fr` toggle.

### Root cause found: stray </div> hoisted the toggle out of controller scope

The collapse toggle never worked because clicks weren't reaching `filter-collapse#toggle` (aria-expanded never changed; the button's nearest controller was `sidebar`/`<body>`). Diagnosed via console: the `[data-controller~="filter-collapse"]` wrapper only contained `.header-top-row` and `.header-collapse-panel` — the `<label>` and `<button>` had been hoisted out.

Cause: a pre-existing extra `</div>` in the recipe-filter block (`.header-collapse-panel` was net -1 on divs). Previously harmless (filter row was the last child), but after moving the counts/options into the header and placing the toggle label+button after the panel, the stray tag closed the wrapper early, pushing those trailing elements outside the controller's element so the action couldn't bind. Removed the stray `</div>`; panel now 12/12, header block 19/19, ERB depth 0.

Note: also fixes the "Show watered plants" toggle (was hoisted out too). Collapse is currently an instant display toggle — smooth animation can be re-added now that scope is correct.

### Counts: single "Showing N Plants - Show All" line + multi-select count

Replaced the two-line counts (needs-water + filtered total) with one line:
- Normal: "Showing %{total} Plants" with a " - Show All" link (clearSearch functionality, label changed from "Clear Search" to "Show All") shown when a search/filter/non-default-display/hide-scheduled is active.
- Multi-select mode: "Selected %{selected} out of %{total} plants" (no Show All link).

N = number of plants currently shown by the active search/filters (the visible/filtered total), computed client-side by location-filter#updateResultsCount.

Implementation:
- ERB: single `<h1 data-location-filter-target="totalCount">` in `.plants-toolbar`; server renders "Showing N Plants" + Show All when `filters_active`. Dropped the wateringCount line.
- location_filter_controller: rewrote `updateResultsCount` — computes visible `total`; if `selection-mode` class present and a `plant-select` controller is on the same element, renders the "Selected X out of N" template (reading `selected.size` via `application.getControllerForElementAndIdentifier`); else "Showing N" + optional Show All link. Removed `wateringCount` target and the 4 old result templates; added `countTemplate`/`selectedTemplate` values; `clearSearchLabel` default now "Show All".
- plant_select_controller: `_refreshCount()` calls the sibling location-filter's `updateResultsCount`; invoked from `toggleMode` and `_updateCount` so the header line updates on mode toggle and every selection change.
- i18n: added `showing_count`, `show_all`, `selected_count` (en + es).

Note: used the shown/filtered total for N (the user's example said "8 of ~50" but wrote "7"; "Showing"/"out of" both use the currently-shown count). Easy to switch to needs-water if that was intended.

## Custom plant image uploads (Active Storage)

Added the ability for users to upload their own plant image instead of only choosing from the predetermined library.

- **Active Storage installed** — `active_storage:install` failed with "Invalid DATABASE provided" because Rails' `railties:install:migrations` reads `ENV["DATABASE"]` as a multi-db config name, but the app repurposes `DATABASE` as the literal db name (`.env`/`database.yml`). Worked around by copying the gem's single migration directly into `db/migrate/` (`*_create_active_storage_tables.active_storage.rb`); user migrated. `image_processing` + `ruby-vips` already bundled; libvips installed locally.
- **Model** (`concerns/plant_graphics.rb`): `has_one_attached :custom_image`; `display_graphic` returns a resized AS variant (`resize_to_limit: [600,600]`) when an upload is attached, else the library asset-path string (custom always wins); `has_graphic?`; content-type (png/jpeg/webp/gif) + 10MB validations. Kept `graphic_path` (library-only) for back-compat.
- **Controller**: permit `:custom_image`; `purge_custom_image_if_requested` purges on `remove_custom_image=1` when no replacement uploaded; called after successful update.
- **Form** (`plants/_form.html.erb` + `plant_graphic_controller.js`): library/upload radio toggle, file input with client-side FileReader preview, current-image thumbnail, hidden `remove_custom_image` flag flipped by the controller (library→"1", upload→"0").
- **Views**: swapped `graphic_path`/`graphic.present?` → `display_graphic`/`has_graphic?` in plants show/edit, `_plant_row` (placeholder fallback), waterings show/new/edit, shared_plants/show, and `application_helper#header_config` (sidebar_graphic).
- **Deploy**: added `storage` to Capistrano `linked_dirs` so uploads survive releases. **Reminder: install libvips on the production server before deploying.**
- **CSS**: `.graphic-source-toggle` / `.graphic-upload-container` in plants.sass.
- **Tests**: model tests (precedence, has_graphic?, content-type validation) + controller tests (attach, remove flag, replacement beats remove); added `test/fixtures/files/plant.png` (1×1 PNG).

## Mobile "Take a photo" option for plant image upload

When uploading a plant image, mobile users can now explicitly choose between taking a photo on the spot and picking an existing one.

- **Form** (`plants/_form.html.erb`): hid the raw `file_field` (`.graphic-file-input`), added a `.graphic-upload-buttons` row with two buttons — "📁 Choose a photo" (`plant-graphic#chooseFile`) and "📷 Take a photo" (`plant-graphic#takePhoto`, `cameraButton` target). Both drive the same hidden input (avoids duplicate-name submission issues).
- **Controller** (`plant_graphic_controller.js`): added `cameraButton` target + `chooseFile()` (removes `capture`, clicks input) and `takePhoto()` (sets `capture="environment"`, clicks input). Camera button is hidden on non-coarse-pointer (desktop) devices since `capture` is ignored there.
- **CSS** (`plants.sass`): `.graphic-file-input { display: none }`, `.graphic-upload-buttons`, `.graphic-upload-btn`.
