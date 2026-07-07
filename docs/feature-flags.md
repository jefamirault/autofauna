# Feature Flags & Onboarding

Five user-level boolean flags (`User::FEATURE_FLAGS`, columns default `true`) hide/show advanced
UI per-user:

| Flag | Gates |
|---|---|
| `track_waterings` | Watering history |
| `use_fertilizers` | Recipes / sources / batches |
| `precise_measurements` | Volume / units / TDS |
| `track_soil_moisture` | Soil moisture readings |
| `has_aquarium` | Tanks section |

Also relevant: `advanced_mode` on User controls visibility of multi-project UI (hidden by default,
independent of the five flags).

## Onboarding wizard

- One-time wizard at `/onboarding` (`OnboardingController`, multi-step view driven by
  `onboarding_controller.js`). Enforced by a global `before_action :require_onboarding` in
  ApplicationController that redirects any signed-in user with `onboarding_completed_at: nil`.
- Controllers that must work pre-onboarding (sessions, settings, auth flows, shared plants,
  transmit, etc.) use `skip_before_action :require_onboarding`. `OnboardingController` itself has
  `ensure_project` so it can seed sources/recipes into `current_project`.

**Wizard steps:**
1. "Which do you have?" → `has_aquarium`.
2. "How do you water?" tap / fertilizer / distilled-RO → `use_fertilizers` enabled when fertilizer
   **or** distilled is chosen (distilled-only still needs the sources/recipes feature on).
   2b. name fertilizers → each becomes a `RecipeSource` + a starter `Recipe`; distilled adds a
   "Distilled / RO Water" source (all via `find_or_create_by`).
3. add a first plant or tank (`next` param → `new_plant_path` / `new_tank_path`).

`skip` completes onboarding with all five flags off.

## Auto-enable-on-first-use flags

`track_waterings`, `precise_measurements`, and `track_soil_moisture` are **NOT asked** in
onboarding — the wizard writes them `false` and they auto-enable via `User#enable_feature!(flag)`
(idempotent `update_column`, raises on unknown flag):

- `track_waterings` ← logging a detailed watering (`waterings#create`). Quick-water
  (`plants#quick_water`) stays ungated and does NOT opt in.
- `precise_measurements` ← submitting a `volume` or `tds` on a watering (`waterings#create`/`#update`).
- `track_soil_moisture` ← creating a soil moisture reading (`soil_moisture_readings#create`), or
  submitting pre/post moisture on a watering.

For these affordances to be reachable while off, the gates carve out the enabling actions:
`WateringsController` → `except: [:create, :new]`; `SoilMoistureReadingsController` →
`except: [:new, :create]`. The volume/TDS/moisture disclosures in `waterings/_form.html.erb` plus
the detailed-watering / "Log Soil Moisture" links in `plants/show.html.erb` always render (not
wrapped in `feature_enabled?`).

## Editing & checking flags

- **Editable any time** from the Settings "Features" card (`settings#update` permits
  `*User::FEATURE_FLAGS`).
- **Views** check `feature_enabled?(:flag)` (ApplicationController helper; returns `true` when
  signed out).
- **Controllers** are gated with `require_track_waterings` / `require_use_fertilizers` /
  `require_has_aquarium` / `require_track_soil_moisture` filters (redirect to `plants_path`).
- The TDS block in `waterings/_form.html.erb` is **outside** the recipes conditional —
  fertilizers-off + precise-on users still get TDS.
- When `track_waterings` is off but `use_fertilizers` is on, the sidebar shows a **Recipes** nav
  item in place of Water (otherwise recipe pages would be unreachable).

## Test fixtures

Users `one`/`two` have `onboarding_completed_at` set (**required** — otherwise every authenticated
controller test redirects to onboarding). User `fresh` is non-onboarded for onboarding tests and
owns `projects(:project_fresh)` (onboarding needs a project to seed into). See `test/CLAUDE.md`.
