# Location Diagram (2D plant layout)

A user-buildable 2D diagram of a location: circular plant chips dragged into place to mirror the
real room. Lives on `locations#show`, with a read-only mini version on `locations#index`.
Issue #115.

## Where the position lives

Two nullable float columns on `plants`: **`layout_x` / `layout_y`, normalized 0.0–1.0**, holding
the chip's **centre** — not pixels. A layout built on a phone therefore reads identically on a
desktop, and the canvas can be any width. `NULL` on either column means "not placed"
(`Plant#layout_placed?` requires both).

A plant belongs to exactly one location, so no join table is needed — but that also means the
coordinates are meaningless once the plant moves:

- `Plant#clear_layout_on_location_change` (a `before_validation`) nils both columns whenever
  `location_id` changes.
- `plants#bulk_set_location` reassigns with `update_all`, which **skips that callback**, so it
  clears the columns in the same statement. Any future bulk relocation path must do the same.

## Placed vs. unplaced

The canvas and the tray are the two homes for a chip, and dragging between them is the whole
placement UI:

- **Canvas** — `position: absolute`, `left`/`top` as percentages, `translate(-50%, -50%)` so the
  stored coordinate is the centre.
- **Tray** ("Not placed yet") — normal flow. Dropping a chip here saves `x: null, y: null`.

The Stimulus controller clamps the centre by the chip's own half-width/height so a chip never
hangs off the edge; the server clamps again to `0..1`.

A chip's label leads with the plant uid (`#37 Fern`) — a location commonly holds several of the
same species, and the bare name made them indistinguishable.

### A drag doesn't change containers until the drop

**`.is-dragging` pins the chip to the viewport** (`position: fixed`, `left`/`top` in px, centre
via `translate(-50%, -50%)`); the chip stays in whatever container it started in, and only
`place()` / `unplace()` on pointerup move it in the DOM. Don't go back to lifting it into the
canvas at the drag threshold: the coordinates get clamped to the canvas, so a pointer still down
in the tray parked the chip on the canvas's bottom edge — it read as a duplicate appearing before
the cursor got there.

The drag also keeps the grab offset (pointer → chip centre), so grabbing a chip by its edge
doesn't snap it under the cursor.

### Tray grouping

The tray groups by **primary recipe** (`plant.recipe`, the `recipe_id` column kept in sync with the
first `plant_recipe`) — so a plant on several recipes files under one heading instead of appearing
twice. Gated on `use_fertilizers`, and skipped entirely when no plant here has a recipe, which
leaves the flat tray exactly as it was.

The partial renders a `[data-recipe-group]` bucket for **every recipe in the location**, not just
the unplaced ones, because `unplace()` has to find its chip's group — it reads the first id out of
the chip's `data-recipe-ids` (position-ordered, so the first *is* the primary). Empty buckets are
`hidden`, and `refreshEmptyStates` re-hides them as chips come and go so no heading is left
stranded.

## Layout: canvas beside a rail

`.diagram-body` splits into `.diagram-stage` (canvas, status, **tray**) and `.diagram-side`
(legend). At ≥1000px those are grid columns, so the legend costs no vertical space; below that the
rail stacks underneath. The whole card is built to clear a laptop viewport without scrolling:

- Above 750px the canvas is **height-driven** — `aspect-ratio: auto` plus
  `height: var(--diagram-canvas-h)` (`clamp(14rem, 46vh, 30rem)`). Normalized coordinates are what
  make this safe: a shorter, wider frame is still a faithful layout. The card takes the full
  content width (no `max-width` — a widescreen should be *used*), so the `vh` term is the only
  thing keeping it on one screen; the rem bounds only guard very short and very tall displays.
  Mobile keeps `4 / 3`.
- **The tray stays full-width under the canvas** — it's the surface you drag *from*, and in the
  rail it was two chips wide and all scrolling. While it's showing (unplaced plants, or Arrange
  mode) a `:has(.diagram-tray:not([hidden]))` rule drops `--diagram-canvas-h` to
  `clamp(11rem, 31vh, 19rem)`, so the tray's space comes out of the canvas rather than off the
  bottom of the screen. The canvas transitions its height so chips glide instead of jumping when
  Arrange opens the tray. The tray itself caps at `10rem` and scrolls internally.
- **The rail spans the body's full height** (canvas + status + tray). Grid items stretch, and the
  legend inside is `position: absolute; inset: 0` — filling the rail while contributing *nothing*
  to the row's sizing, so a long legend scrolls inside the rail rather than stretching the row and
  leaving dead space beside the canvas. The partial omits `.diagram-side` entirely when there's no
  legend, and the grid is applied via `.diagram-body:has(.diagram-side)`, so an empty column is
  never reserved.
- **Canvas and tray are drag-resizable** above 750px (CSS `resize: vertical`; both already have a
  non-visible `overflow`, which is the prerequisite). The tray gets a definite
  `height: var(--diagram-tray-h)` rather than a `max-height` — a max-height caps growth, so the
  handle would only shrink. Don't add a height `transition` to either: it fights the handle and
  makes the drag feel rubbery.

  Heights persist per device (`location-diagram-canvas-height` / `-tray-height`). The controller
  keys off the fact that **a resize handle writes an *inline* height** — CSS-driven changes (the
  tray opening and shortening the canvas, a window resize) never set one, so only deliberate
  resizes are stored. The `ResizeObserver` that triggers the save must stay read-only; writing to
  the DOM from it would loop. Restore is skipped below 751px, where the canvas is aspect-ratio'd
  and a stored pixel height would be wrong.

The controller is indifferent to all of this — targets are found anywhere in its scope, and
`isOverTray` is `getBoundingClientRect`-based, so the tray is a drop zone wherever it sits.

The `locations#show` order is diagram → supplies → info card: the diagram is what the page is for,
so the name/zone details sit past the fold. For the same reason `.location-photo` is capped at 9rem
(tanks keep the shared 18rem) — it sits directly above the diagram, and the diagram can already
show that photo as its backdrop.

## Saving

`PATCH /locations/:id/layout` → `LocationsController#update_layout`, route named `layout_location`
(the action can't be called `layout` — too close to Rails' own layout machinery).

Payload is `{ positions: [{ id:, x:, y: }, …] }`; the controller batches and debounces so dragging
several chips in a row is one request.

Two things to preserve:

- **Ids are untrusted.** `update_layout` filters them through `@location.plants` before writing —
  the same project-filtering discipline as `assign_plant_groups`. A plant id from another project
  *or another location* is silently ignored, not written.
- **Writes use `update_columns`, not `update!`.** Coordinates are already clamped, and a chip move
  must not fail because the plant carries an unrelated validation error (a duplicate `uid` from an
  import, say). The `layout_x`/`layout_y` range validation on `Plant` still guards every other path.

Read access follows the page: `authorize_viewer` for `show`, `authorize_editor` for
`update_layout`. Viewers see the diagram; the "Arrange" button is only rendered when `can_edit?`,
and the controller's `editableValue` gates dragging on the client too.

## The legend

Groups and recipes are derived from **the plants standing in this location**, not the project-wide
lists — `LocationsController#show` tallies `@diagram_plants.flat_map(&:plant_groups)` (and
`&:recipes`, behind the `use_fertilizers` flag). Clicking an entry highlights matching chips and
dims the rest; that state is presentation-only, never persisted.

## Index mini-diagram

`locations#index` loads coordinates in a **separate query** (`@layout_points`). The main relation
is `left_joins(:plants).group('locations.id')` for the plant-count ordering, so plant rows can't be
preloaded onto it — don't try to fold this back into one query with `includes(:plants)`.

The card's thumbnail slot shows the mini-diagram when a layout exists (keeping the photo as a faint
backdrop), and otherwise falls back to the plain photo thumb or to no thumbnail — so a user who
never builds a layout sees exactly the card they saw before.

## Files

| Concern | File |
|---|---|
| Controller actions | `app/controllers/locations_controller.rb` |
| Canvas / tray / legend markup | `app/views/locations/_diagram.html.erb`, `_diagram_chip.html.erb` |
| Index card | `app/views/locations/_location.html.erb` |
| Drag, save, highlight | `app/javascript/controllers/location_diagram_controller.js` |
| Styles | `app/assets/stylesheets/locations.sass` |
