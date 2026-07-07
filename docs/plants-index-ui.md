# Plants Index UI & Group Watering

The plants index (`/plants`, the app root) is the main page and the most client-side-heavy
surface in the app. This doc covers its rendering model, the Stimulus coordination, plant
groups / bulk watering, and the many Turbo/Rails gotchas that live here.

> **Invariants that also live in the root `CLAUDE.md`** (repeated here for context):
> triple-rendered cards require `replace_all` (not `replace`); `button_to` inside
> `turbo-frame#plants-results` must NOT get `data: { turbo_frame: "_top" }`; navigating links
> DO need `_top`; `Plant has_many :waterings` has a default order scope (use `reorder`);
> watering `after_save_commit` may not have committed when a stream renders.

## Rendering model

- **Display modes:** Watering (flat list by urgency), Location (grouped), Recipe (grouped) —
  all rendered **server-side**, toggled client-side.
- **Triple-rendered cards:** every plant card is rendered 3× (once per display mode); only one
  mode is visible at a time (CSS `display: none`). All three share the same `dom_id`. Turbo
  Stream actions must therefore use `replace_all` (CSS selector via `targets:`), not `replace`
  (single id via `target:`), or only the first DOM instance updates.
- **Filters:** Status (Overdue / Needs Water / Scheduled), Recipe, Location — client-side, AND
  logic, toggleable visibility.
- **Pagination:** client-side, configurable per-page count.
- **Search:** debounced auto-submit via the header search bar, with a clear button.

## Plant cards (`_plant_row.html.erb`)

Urgency-tinted cards (`normal` / `scheduled` / `needs_water`) with a **watering-status spine** —
a saturated `border-left` in the urgency hue (blue / green / amber): **left = status, right =
the full-height water button**. Structure:
`.plant-card-graphic-col` (photo) | `.plant-card-body` (wraps `.plant-card-name` over
`.plant-card-details`) | `.plant-card-water-wrap`.

- The title splits `plant.uid` into a monospaced `.plant-card-accession` tag ("#90") +
  `.plant-card-common-name` (rendered separately, **not** via `plant.label`).
- `.plant-card-details` holds the semibold watering-countdown line + `.plant-card-meta`
  (attribute lines in a **single-column** grid — each show/hide-able and drag-reorderable via
  the card-fields menu).

### Responsive layout
- `.plant-cards` is single-column by default, 2-col ≥1200px, 3-col ≥1550px (cards are narrow
  since attributes are single-column).
- At **≤500px** the card stacks into four full-width rows — title / full-width photo hero /
  details box / water button — via `.plant-card-body { display: contents }` (lifts the title out
  of the middle column) + flex `order`. The photo goes `height:auto` full-width
  (`max-height:70vh`); title/details/button font sizes scale up to match.

### Quick water
Water button is a `button_to` (POST) creating a watering inline via Turbo Stream. Card updates
to "Watered!" + edit link (full-column `link_to`). Uses `aria-busy` CSS for optimistic feedback.
The `<form>` has `padding: 0` and the `<button>` inside carries the padding so the whole column
is clickable. `.plant-card-water-col` has `min-width: 6rem` to prevent width changes when content
swaps between states.

## Header (collapsible search panel)

`header_extra` renders a `display:contents` wrapper
(`data-controller="location-filter filter-collapse"`) holding:
- `.header-top-row` (flex/wrap) = `#headerSearch` (search form) + `.saved-searches-row`;
- `.header-collapse-panel` > `.header-collapse-inner` = the location/recipe filter buttons
  (`.filter-row-content`) + `.sort-toggle-row` (sort/display-mode buttons + the **"Hide watered
  plants" checkbox**, `name=hide_scheduled`, linked to the search form via `form="plantSearchForm"`);
- a floating rectangular `.filter-collapse-btn` handle straddling the header's bottom edge.

Panel is **collapsed by default** (`filter_collapse_controller`).

**Saved searches hide with the panel:** `.saved-searches-row` (chips + "name this search" save
form) is `display:none` while collapsed, shown only when expanded
(`header:has(.filter-collapse-btn[aria-expanded="true"]) .saved-searches-row`) at all widths, so
chips don't wrap and clutter the minimized header. The hide targets the **row**, not the children,
because the save form's visibility is set via a JS-managed **inline** `style.display`
(`location_filter#updateSaveFormVisibility`) that would override a selector-based rule on the form
itself; a `display:none` ancestor hides the subtree regardless.

## Counts toolbar

`.plants-toolbar` sits at the **top of the results frame** (NOT the header). Shows "Showing N
Plants" + a " - Show All" link (= `clearSearch`; rendered when a search/filter/non-default-display/
hide-scheduled is active) via `location_filter#updateResultsCount`. In multi-select mode it reads
"Selected X out of N plants". The "☑ Select" button is left-aligned here, right after the counts.
N is the client-side filtered/visible count.

## Multi-select / bulk actions

The "☑ Select" toggle (`plant_select_controller#toggleMode`) reveals per-card checkboxes + a
bulk-action bar (Water selected / Create group / Add to group / Set location / Archive). In
selection mode the **whole card toggles selection** (`plant_select#cardClick`) **except** the
watering column (`.plant-card-water-wrap`) and the checkbox; plant-show and location links are
disabled via `.selection-mode { pointer-events: none }` so their clicks fall through to the card.
Selection is keyed by plant id and synced across the triple-rendered cards.

The per-card checkbox (`label.plant-card-select`) is **hidden by default via an inline
`style="display: none;"`** (NOT a CSS class or the `hidden` attribute), toggled by
`_showCheckboxes`. See the "inline style vs stale CSS" gotcha below. Every selection/mode change
calls `_refreshCount()` → the sibling `location_filter#updateResultsCount`.

## Card fields menu (⚙️)

A cog button floating in the **header's bottom-right corner** (`.card-fields-menu` in
`header_extra`, positioned `absolute` relative to `<header>`; `card_fields_controller`) opens a
two-column dropdown: a **draggable example card preview** (left) + a **show/hide checklist**
(right). Users toggle which attribute lines appear and drag preview rows to reorder. Both prefs
persist per-device in localStorage (`plant-card-hidden-lines`, `plant-card-line-order`) and apply
to every real card via a single injected `<style id="plant-card-line-toggles">` in `<head>`
(`display:none !important` + grid `order` rules), so they survive display-mode switches,
pagination, and Turbo Stream replaces. "Next watering" is a fixed headline (not reorderable); the
6 `.plant-card-meta` fields are. Since it lives outside `turbo-frame#plants-results`, the
controller doesn't re-init on search.

## Plant Groups & Group Watering

Plants can be watered one-at-a-time or in bulk. Bulk watering reuses **`Plant#quick_water!(at:)`**
— the carry-forward logic (copies the last watering's volume/units/notes/recipe/batch/tds),
extracted from `PlantsController#quick_water` so single and group watering share it.

**Two grouping mechanisms (both supported):**
- **Locations as implicit groups** — `Location#water_all!` waters every non-archived plant in the
  location. The plants index renders a "💧 Water all" `button_to` (`water_all_location_path`) in
  each location group header (gated by `can_edit?`, an ApplicationController helper); it lives
  inside `turbo_frame#plants-results` so the Turbo Stream response updates every card. Location
  show page also has "Water all" + "Create a group from these plants".
- **`PlantGroup` model** — custom, possibly cross-location collections. `PlantGroupsController` is
  standard CRUD (auth checklist like LocationsController) + `member post :water` (`water_all!`) +
  `collection post :seed_from_location`. `PlantGroup#apply_schedule_to_members!` pushes the group's
  min/max freq onto members (opt-in `apply_schedule` checkbox). Reachable via a "👪 Groups" nav item.

**Turbo Stream DRY:** `plants/_watered_streams.turbo_stream.erb` (locals `plant`, `watering`)
holds the `replace_all "##{dom_id(plant)}"` (triple-rendered cards) + `replace dom_id(plant, :show)`
pair. `quick_water`, `plant_groups/water`, and `locations/water_all` all render it (the bulk ones
loop over `@watered`).

**Plant form:** group membership is a checkbox block (`plant[plant_group_ids][]` with a leading
hidden blank to allow clearing); `PlantsController#assign_plant_groups` filters ids to
`current_project.plant_groups` (prevents IDOR), mirroring `assign_plant_recipes`.

**Deferred (Phase B):** a dedicated "Groups" *display mode* on the index was NOT built — a plant
in multiple groups would render duplicate cards with the same `dom_id` in one visible container,
breaking `location_filter_controller.js` pagination/count logic. Manual-group watering is reached
via the group show page. Also future: a 0/1/2 per-plant/per-group tracking-level continuum
(default on Project, override on plant/group).

## Turbo / Rails gotchas specific to this page

- **`plants/_plant.html.erb` reads the `@plant` ivar, not a `plant` local** (unlike
  `_plant_row.html.erb`). `render @plant` only works when `@plant` is set. Bulk watering has no
  `@plant`, so `_watered_streams.turbo_stream.erb` sets `@plant = plant` before the show-view
  `replace`. Any new context rendering the `_plant` show partial must set `@plant`.
- **Nested route param names:** routes nested in `resources :plants do` (`get 'water'`,
  `post 'quick_water'`) use `params[:plant_id]`, not `params[:id]`. `set_plant` uses `params[:id]`,
  so these actions find the plant manually via `current_project.plants.find(params[:plant_id])`.
- **`button_to` inside `turbo-frame#plants-results`** returns streams fine — do NOT add
  `_top` (breaks the stream into a page navigation, reverting the update). Links that navigate
  away DO need `data: { turbo_frame: "_top" }` or they show "Content Missing".
- **`display:contents` header wrapper — keep its HTML perfectly balanced.** A stray/mismatched
  tag inside the `<div style="display:contents" data-controller="location-filter filter-collapse">`
  makes the browser close the wrapper early and **hoist trailing elements out of it** — they fall
  outside the controllers' scope and their Stimulus actions silently never bind (symptom: clicking
  does nothing, `aria-expanded` never flips, though the controller is connected). `display:contents`
  doesn't change the DOM tree, so `btn.closest('[data-controller]')` still reveals the real parent
  — use it to debug. Verify `<div>`/`</div>` balance **per block**, not just file-wide.
- **`aria-busy` loading state:** setting `aria-busy="true"` on `turbo-frame#plants-results`
  (manually before `requestSubmit`, then Turbo-managed) dims `.plant-cards` and
  `.pagination-controls`. `_resetInstantly()` on `location_filter_controller` does the immediate
  client-side reset (clear inputs, deactivate filters, remove clear-search links) before the
  server round-trip.
- **Default-hide with inline `style="display:none"`, not a class or `hidden`, when stale compiled
  CSS is a risk.** The multi-select checkbox uses inline style. A `.plant-card-select{display:none}`
  rule and the `hidden` attribute both failed in dev because the running server served a **stale
  compiled stylesheet** with `.plant-card-select{display:flex}`. Inline style (specificity 1,0,0)
  beats any selector-based author rule and lives in fresh server-rendered ERB (no Sprockets
  recompile). **General lesson:** if a `display`/visibility change "isn't taking effect" in dev,
  suspect stale assets. (Note: SASS *does* reload on refresh — see `docs/deployment.md`; the stale
  case here was a compiled artifact, not a live SASS edit.)
- **N+1:** use `.includes(:location, :recipe, :last_watering)` on the Ransack result.
- **Plant model N+1 risks:** `first_watering`, `last_fertilized`, `suggested_watering_unit`,
  `calculate_watering_frequency` each load the `waterings` collection. `last_watering` uses
  `belongs_to :last_watering` (eager-loadable) with a `waterings.last` fallback. `graphic_path`
  calls `available_graphics` which does an unmemoized `Dir.glob` every call.
- **`params[:q]` with Ransack:** use `params[:q]&.to_unsafe_h` when passing search params to URL
  helpers.
- **`prompt:` vs `include_blank:`** on `collection_select`: `prompt:` shows only when value is nil;
  `include_blank:` always shows (use for "None" on edit forms).

## Coordinating Stimulus controllers

`location_filter_controller.js` handles filtering, pagination, display-mode switching, and the
counts line. It runs as **two coordinating instances** — see
`app/javascript/controllers/CLAUDE.md` for the dual-instance mechanics and the other index
controllers (`filter_collapse`, `card_fields`, `plant_select`).
