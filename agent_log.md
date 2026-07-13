# Agent Log

Chronological journal of significant changes this session-series. Append a short summary after each
significant task. **Rotate when this file exceeds ~30 KB** — move it to
`agent_log/agent_log_<min-date>_to_<max-date>.md`, add a line to `agent_log/README.md`, and start a
fresh file. See the Agent Log section of `CLAUDE.md`.

---

## 2026-07-07 — Rotated agent_log (Mar–Jul 2026 → archive)

Active log had reached 56 KB / 520 lines spanning 2026-03-20 → 2026-07-07 (~3.5 months, overdue).
Moved it to `agent_log/agent_log_2026-03-20_to_2026-07-07.md` and started this fresh file. Also
created `agent_log/README.md` (an index of all archives, one line each with date range + topic
hook) and added a size-trigger rotation rule (~30 KB) to `CLAUDE.md`. Entry order in the archive is
intentionally non-chronological in places — it reflects concurrent sprint-worker appends and is
left as an accurate record.

## 2026-07-07 — Plant card redesign (moisture bloom + watering-window gauge)

Redesigned the plants-index card (prototyped standalone with screenshots before touching the app).
The flat urgency tint became a **moisture bloom** — the hue soaks in from the status spine and
fades out, so text sits on near-white while status still scans at the left edge. All hue surfaces
now derive from CSS vars (`--hue`/`--hue-ink`/`--hue-soft`/`--hue-wash`) set per urgency class;
quick-water aria-busy flips the vars to blue ("card drinks" optimistic feedback). New signature
element: a **watering-window gauge** under the countdown (track = last watering → max due date or
today when overdue; translucent band = min→max window; fill = elapsed, overshoots the band when
late) via `PlantsHelper#watering_gauge_style` inline custom properties. Meta emoji got a fixed
icon column (`.mi`/`.mv` spans) so values align; accession uid restyled as a nursery-tag chip;
snoozed cards desaturate (`.snoozed`); water button copy shortened to "Water"/"Regar" (en/es).
`card_fields_controller` hides the gauge together with the "Next watering" line. Helper unit
tests added (`test/helpers/plants_helper_test.rb`). Docs: plant-cards section of
`docs/plants-index-ui.md` rewritten. Files: `plants.sass`, `_plant_row.html.erb`,
`plants_helper.rb`, `card_fields_controller.js`, `en.yml`/`es.yml`.

## 2026-07-08 — Plants index: Load More pagination + Back to Top

Replaced the watering-mode page-number pagination (per-page select 10/20/50/All, prev/next +
numbered buttons) with a fixed 50-per-page **"Load More..."** reveal: clicking shows the next 50
cards without hiding earlier ones (`currentPage` now counts revealed batches; `PER_PAGE = 50`
module const, `perPage` Stimulus value removed along with `changePerPage`/`goToPage`/
`createPageButton`). `showing_info` locale changed to "Showing %{shown} of %{total}" and only
renders while truncated. Also added a **"Back to Top"** button below the results (own container,
all display modes — pagination-controls stays watering-only): shown only when `<main>` (the
scroll container) overflows, smooth-scrolls it to 0; visibility refreshed in
`paginateVisibleCards` and `updateResultsCount`. Files: `location_filter_controller.js`,
`plants/index.html.erb`, `plants.sass`, `en.yml`/`es.yml`, `docs/plants-index-ui.md`.

## 2026-07-08 — Plant card column ladder + mobile layout toggles

Widened the plants-index grid ladder to **2 / 3 / 4 columns at ≥1200 / ≥1550 / ≥1900px**; in grid
modes cards get `min-height: 15.5rem` and a wider photo column (170px, 150px at 4-up where the
water column also slims) so the full-height image reads as a **portrait plate**. Unified the
stacked-card breakpoint with the site mobile breakpoint (**500px → 600px**) and added mobile-only
**layout toggles** to `.plants-toolbar`: a 1↔2 column segmented control + a photo-size button
(visible in 1-col only; compact caps the hero at 10rem — default stays the full-width hero).
2-col is a portrait gallery (aspect-ratio 3/4 photo box, compact type, water row pinned to the
bottom of equal-height rows). New `card_layout_controller` stamps `plant-cols-2` /
`plant-img-compact` on `<html>` (survives turbo-frame reloads), persists to localStorage
(`plant-mobile-columns`, `plant-mobile-image`); all rules scoped inside the ≤600px media block so
the classes are inert on desktop. Verified via compiled-CSS static harness + headless screenshots
at 1950/1300/390px in all toggle states. Files: `plants.sass`, `plants/index.html.erb`,
`card_layout_controller.js`, `en.yml`/`es.yml`, docs (`plants-index-ui.md`, controllers
`CLAUDE.md`, autofauna-ui skill).

**Follow-up (same day):** grid-mode (≥1200px) cards restructured into an internal CSS grid —
columns `[select] [photo] [text]`, rows `1fr auto`. Photo spans the full card height; the water
button leaves the right edge and becomes a horizontal bottom row of the text column (dashed top
divider, mirroring the mobile stacked layout — the expanded inline watering form now gets that
full-width row too). `min-height` bumped 15.5rem → 19rem. Below 1200px the classic right-edge
water column remains. Re-verified via harness screenshots at 1950/1300px. Files: `plants.sass`,
docs.

**Follow-up 2:** grid-mode photo track resized from fixed 170px to **min-height × 3/4**
(14.25rem; 4-up: min-height 17.5rem → 13.125rem track) with zero graphic inset, so a portrait
4:3 image fills the full card height as an edge-to-edge plate (other ratios letterbox via
`object-fit: contain`). Verified with a generated 600×800 test photo in the harness at
1950/1300px. Files: `plants.sass`, docs.

**Follow-up 3:** removed the card's expand-watering caret and the in-place watering form (it
broke the new grid-mode formatting; the watering edit view covers the use case). Deleted
`plants/_inline_watering_form.html.erb`; `inline_watering_controller` slimmed to just the
quick-water double-submit guard; `WateringsController#create` turbo_stream failure branch now
returns an empty 422 stream (quick-water data is valid by construction). The card's quick snooze
went with the panel — snooze/unsnooze remains on the plant show page; snoozed state still shows
on cards. Pruned card-only CSS (`.expand-watering-btn`, `.plant-card-inline-form`,
`.inline-watering-*`, `.inline-water-*`, `.inline-snooze-*`); kept `.inline-field*`/`.inline-input`
(bulk-water bar) and show-page snooze styles. Files: `_plant_row.html.erb`,
`inline_watering_controller.js`, `waterings_controller.rb`, `plants.sass`.

## 2026-07-08 — Group "Water all" → "Select all" (plants index)

Replaced the per-location "💧 Water all" `button_to` in location group headers with a
"☑ Select all" button, and added the same button to recipe group headers (which had no bulk
action before). New `plant_select#selectGroup` action: enters selection mode if needed, then
toggle-selects the group's visible (non-`data-filter-hidden`) cards; re-click deselects just that
group. Bulk "Water selected" is now the index's water-all pathway (location show page keeps its
direct "Water all"). Removed now-unused `plants.index.water_all` locale key (en/es) and the
`.group-water-all-*` styles (`.group-watering-bar` → `.group-select-bar`); added es
`plants.bulk.select_all`. Files: `plants/index.html.erb`, `plant_select_controller.js`,
`shared.sass`, locale files, docs.

**Follow-up (design pass):** the group "Select all" moved from a generic pill in its own bar
into the group header itself — a stateful chip on the header's right edge (the app's action
edge). Colors derive from the group's color via inline `--group-color(-soft/-tint)` vars on the
`<h3>`: idle = white ghost pill with a soft group-color hairline; active (whole group selected) =
group-tint fill + solid border + "✓ Selected", ink always `$blue` since free-form group colors
can be too light to read. `plant_select#selectGroup` gained `stopPropagation` (header click
collapses the group) and `_refreshGroupButtons()` keeps every chip's state live from
`_updateCount`; `aria-pressed` + `:focus-visible` outline included. ≤600px the header flex-wraps
(count hugs the name, chip owns the right edge). Removed the `.group-select-bar`; added
`plants.bulk.group_selected` (en/es). Verified via compiled-CSS harness screenshots at
900/390px incl. a light-yellow worst-case group color. Files: `plants/index.html.erb`,
`plant_select_controller.js`, `plants.sass`, `shared.sass`, locales, docs.

## 2026-07-08 — Watering edit/new form redesign (sectioned form + chip rail)

Restructured the bare waterings `_form` into labeled sections — eyebrow labels (When / Mix /
Measurements / Notes) with hairline rules, colored by `var(--section-color-start)` so they pick up
the waterings blue (reusable on any section). Optional fields (volume, TDS, pre/post moisture) now
toggle via dashed `.chipButton` pills in one `.chip-row` at the end of Measurements; hidden field
containers sit directly above the row in fixed order (Stimulus targets/actions unchanged). Added a
"Now" quick-set next to the datetime field (inline onclick). New shared classes: `.card-title-row`
(h2 + plant pill replaces the redundant Plant field), `.card-footer-actions` (quiet
discard/delete row), `.form-errors`. **Styled the previously-unstyled `.buttonLinkSmall`**
(neutral outline pill; placed before `.buttonLink`/`.buttonLinkDanger` so the weather page's
`buttonLinkSmall buttonLinkDanger` combo keeps danger colors) — also improves onboarding/weather.
`.field-row` gained `margin-bottom`, `min-width: 0` (mobile shrink) and a trailing-small-button
slot. Copy: prompts de-dashed ("None — use recipe below"), i18n'd new strings (en/es incl.
missing `waterings.new_watering`). Verified via compiled-CSS harness screenshots at 1280/390px
(state: volume+TDS+recipe present). Files: `waterings/_form|edit|new.html.erb`, `shared.sass`,
`en.yml`/`es.yml`, autofauna-ui skill.

## 2026-07-08 — Plant edit/new form gets the sectioned-form pattern

Extended the watering-form redesign to the plants form: eyebrow sections **Basics** (name,
number, container — pot moved up), **Where** (location smart-select, groups), **Care** (watering
frequency, recipes — recipes moved after freq), **Photo** (graphic selector; its old label line
replaced by the eyebrow). Eyebrows/card border pick up plants green (#2E7D32) via
`--section-color-start`. Edit page: `.card-title-row` ("Edit Plant" + plant pill, new
`plants.edit_plant` key) + `.card-footer-actions` (quiet discard/delete). New page: **removed the
h1 breadcrumb** (violated the no-breadcrumbs rule) in favor of a card h2. Errors box switched
`auth-errors` → `form-errors`. Fixed two more never-styled classes: `.recipe-checkboxes`
(checkboxes were full-width via global `input {width:100%}`, floating away from labels — now a
flex list) and `.smart-select`/`.suggestion-chip` (suggested-location pills, `.selected` fills
with section color); also `input[type=radio] width:auto` in `.graphic-source-toggle`. Prompts
"-- None --" → "None" (i18n'd, en/es). Stimulus `plant-graphic` targets untouched. Verified via
compiled-CSS harness screenshots at 1280/390px. Files: `plants/_form|edit|new.html.erb`,
`shared.sass`, `plants.sass`, `en.yml`/`es.yml`, autofauna-ui skill.

## 2026-07-08 — Soil moisture + log entry forms brought into the card pattern

Both were unfinished: log entry pages had **no card at all** (bare h1 + breadcrumbs on the page
background, a 5-select `datetime_select`, inline-red errors); soil moisture used four unstyled
classes (`.formContainer`, `.button`, `.subtitle`, `.danger-zone`) plus **three missing i18n keys**
(`edit_log_entry_for`, `delete`, `are_you_sure`) and a `data:{confirm:}` delete that never fired
under Turbo. Now: both controllers added to the shared centered-card + form-styling selector lists
in `shared.sass` (that shared block also gained `textarea{width:100%}`); cards get
`.card-title-row` (title + plant pill) and `.card-footer-actions` (cancel; soil moisture edit also
a quiet delete with a working `onclick` confirm, new `soil_moisture_readings.delete/
confirm_delete` keys); errors → `.form-errors`; log entry timestamp switched to
`datetime_local_field` + "Now" chip (permitted params already accept the scalar); soil moisture
`measured_at` also gets a "Now" chip. Consolidated the "Now" label into `actions.now` (waterings
form switched over; dropped `waterings.form.now`). Added `log_entries.edit`,
`soil_moisture_readings.save/select_prompt` (en/es). No eyebrow sections — 2–3-field forms don't
need them. Verified via compiled-CSS harness screenshots at 1280/390px. Files:
`soil_moisture_readings/*`, `log_entries/_form|edit|new.html.erb`, `shared.sass`, locales, skill.

## 2026-07-08 — Uploadable pictures for Tanks

Added a single uploadable photo per Tank (`has_one_attached :picture`, no migration — Active
Storage already in place from plant custom images). Model validates content type (PNG/JPEG/WEBP/GIF)
and 20MB cap; `picture_attached?` guards against unpersisted blobs after a failed save (same
pattern as `PlantGraphics#custom_image_attached?`). Controller permits `:picture`, purges on
`remove_picture=1` (skipped when a replacement is uploaded), and index eager-loads via
`with_attached_picture`. New generic `image_upload_controller.js` Stimulus controller (choose/take
photo buttons, client preview, remove flag) — plant_graphic_controller stays coupled to the
graphics library. Form reuses the global `.graphic-upload-*` classes. Tank cards
(`_tank.html.erb`) show a 3.5rem thumbnail (`.resource-card.with-photo` flex layout in
`shared.sass`); tank show renders the photo above the info card with the existing `image-lightbox`
controller (hi-res 1600px variant). Six new controller tests mirror the plants image tests.
Files: `tank.rb`, `tanks_controller.rb`, `tanks/_form|_tank|show.html.erb`,
`image_upload_controller.js`, `shared.sass`, `tanks_controller_test.rb`.

---

## 2026-07-13 — Security audit + fix of three cross-tenant (IDOR) findings

Full manual security review of the app + deploy config + `~/devops` static-site infra (report
saved to a Google Doc). Three HIGH findings shared one root cause: **tenant scope derived from a
request param / a separately-tracked `current_project` that authz checks were desynced from,
instead of from the authenticated user + the object being acted on.** Fixing all three:

1. **`SensorReadingsController`** — `set_project` switched `current_project` from an arbitrary
   `project_id` param with no membership check, and `authorize_viewer` (only `readings`) ran
   *before* it, so `readings` leaked any project's data; `import`/`process_file` had no auth at all
   (unauthenticated cross-tenant write). Fix: `authenticate` + `ensure_project` (except
   `transmit`), `authorize_viewer` on `readings`, `authorize_editor` on `import`/`process_file`;
   removed the param-switching `set_project`. `transmit` stays public (API-key auth) and resolves
   its project locally; also scoped its `Sensor` lookup to the authenticated project
   (`project.sensors.find_by`) so a cross-project sensor_id can't be attached (was a Medium
   finding). Behavior change: missing `project_id` on transmit now renders its own "Unauthorized"
   (200) instead of a redirect — transmit test updated to match.
2. **`ProjectsController#set_project`** — did an unscoped `Project.find(params[:id])` and only
   switched `current_project` for members, leaving `@project` = victim while authz checked the
   attacker's own project → any editor could read/update (rename, rotate `api_key`) any project by
   id. Fix: `set_project` now raises `RecordNotFound` unless `authorized?(current_user, :viewer,
   @project)`, then sets current_project to `@project` so downstream authz evaluates the target.
3. **`plant_params` permitted `:project_id`** → editor could create/move a plant cross-tenant.
   Fix: dropped `:project_id`; `create` now uses `current_project.plants.new(plant_params)`.

Regression tests added to `authorization_test.rb` (projects read/update deny, plant create/move
deny) + new `sensor_readings_authorization_test.rb` (unauth import blocked, cross-tenant readings
blocked). NOTE: remaining mediums from the audit (non-constant-time api_key compare + key in query
string, no rate limiting, nginx `add_header` inheritance dropping security headers, commented-out
Rails CSP) are documented but NOT yet fixed.
