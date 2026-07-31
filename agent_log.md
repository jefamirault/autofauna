# Agent Log

## 2026-07-17 — Implement #113 (unified fertilizer picker on watering form)

Executing `docs/specs/issue-113-fertilizer-picker.md`. Plan:

1. **Migration** — `pinned:boolean default:false null:false` on `recipes` + `recipe_sources`.
2. **Models** — `scope :pinned` on both; `Watering#mix_belongs_to_plant_project` validation
   (recipe/source/batch project must match plant's project when present).
3. **Strong params** — permit `:pinned` in `recipes_controller` + `recipe_sources_controller`.
4. **Recipe / RecipeSource forms** — "Pin to watering shortcuts" checkbox (hardcoded English to
   match the surrounding un-i18n'd forms — deviation from spec 4.5, which assumed an i18n namespace
   that doesn't exist for these forms).
5. **Picker partial** — new `waterings/_fertilizer_picker.html.erb`: chip row (None + pinned/current
   + More…), 3 hidden fields, server-rendered search panel, batch `<select>`. Smart-suggestion
   fallback when nothing pinned. Batches embedded as `data-batches` JSON incl. current inactive one.
6. **New Stimulus `fertilizer_picker_controller.js`** — pick/togglePanel/search/batchChanged;
   derives selection from hidden fields on connect; dispatches `tds` event.
7. **`watering_recipe_controller.js` cleanup** — remove form-only `sourceChanged`/`sourceSelect`/
   `recipeSection` + dead `unifiedBatch*`/`recipeIdHidden` + `projectUrl` value; add `applyTds`.
   **Deviation from spec 4.3:** KEEP `recipeChanged`/`batchChanged`/`recipeSelect`/`batchSelect`/
   `tdsField`/`url` — the plants-index bulk-water panel (out of scope, must stay working) still
   uses them. Likewise KEEP the `for_recipe` endpoint; only remove `for_project` (form-only).
8. **Styles** — `.fertilizer-picker` in shared.sass next to `.smart-select`.
9. **i18n** — `waterings.form.picker_*` keys in en + es; remove `none_use_recipe`.
10. **Tests** — model (pinned scope + validation), controller (pinned persist, create fidelity,
    cross-project reject), system (chip/search/batch/edit round-trip).

**Outcome (implemented):** All of the above landed. Files: migration
`20260717000002_add_pinned…`; `schema.rb` bumped by hand (version + two columns) to stay consistent
pending `db:migrate`. Models: `pinned` scope on Recipe/RecipeSource; `Watering#mix_belongs_to_plant_project`.
New `waterings/_fertilizer_picker.html.erb` + `fertilizer_picker_controller.js`; `_form.html.erb`
swaps the three selects for the partial and adds `fertilizer-picker:tds->watering-recipe#applyTds`.
Styles in `shared.sass`; picker i18n in en+es; `none_use_recipe` removed. Pin checkbox on both
recipe/source forms (hardcoded English — those forms are un-i18n'd; **deviation from spec 4.5**).

**Key deviation from spec 4.3/3.2:** the plants-index bulk-water panel (`plants/index.html.erb`,
out of scope) *also* consumes `watering-recipe`'s `recipeChanged`/`batchChanged`/`recipeSelect`/
`batchSelect`/`tdsField`/`url` + the `for_recipe` endpoint. So I KEPT those and only removed the
genuinely form-only/dead bits: `sourceChanged`/`sourceSelect`/`recipeSection`,
`unifiedBatch*`/`recipeIdHidden`, `projectUrl` value, and the `for_project` endpoint+route. Added
`applyTds`. Updated `controllers/CLAUDE.md` roster.

**Tests:** model (`watering_test`, new `recipe_test`/`recipe_source_test`), controller (new
`recipes`/`recipe_sources` update-pinned, extended `waterings_controller_test`). Because the picker
is fully server-rendered, the "system" acceptance (chip vs panel placement, unpinned-absent,
"(inactive)" edit round-trip, id fidelity, cross-project reject, no-pins fallback) is covered by
integration assertions with `assert_select` rather than Capybara — the system-test harness here has
no auth wiring and its existing waterings/plants system tests are stale scaffold (reference
nonexistent fields, never sign in). New fixtures: `recipes(:pinned_grow)`, `recipe_sources(:cal_mag)`
pinned.

**Needs user:** `bin/rails db:migrate` then `bin/rails test`. (Migration + tests not run here — I
can't run `bin/rails`.)

## 2026-07-30 — Filed #115 (location diagram: drag-and-drop 2D plant layout)

Issue only, no code. Feature request from Jef: build a 2D diagram per Location where circular plant
chips are dragged into place to mirror the real room, as another way to visualize the plant data.
Scoped to `LocationsController` + `locations/show`, `locations/index`, `locations/_location`.

Three design questions resolved with Jef before filing, and baked into the issue body:
- **Canvas** — blank grid by default, Location photo (from #110) available as an *optional* faint
  backdrop rather than required.
- **Groups/recipes side list** — a legend derived from the plants actually in the location (not the
  project-wide list), click-to-highlight matching chips; fertilizer half behind `use_fertilizers`.
- **Index** — read-only mini-diagram on location cards, falling back to today's card when a location
  has no layout.

Issue body records the suggested persistence shape (nullable `layout_x`/`layout_y` floats on
`plants`, normalized 0.0–1.0 so the canvas can be responsive), the multi-tenancy requirement for the
layout-save endpoint (filter plant ids through `@location.plants`, mirroring `assign_plant_groups`),
and the trap in the existing index query (`left_joins(:plants).group('locations.id')` — don't bolt
`includes(:plants)` onto it). Labels: enhancement, UX/UI. No milestone.

https://github.com/jefamirault/autofauna/issues/115

## 2026-07-30 — Implement #115 (location diagram: drag-and-drop 2D plant layout)

Built the feature filed earlier today. Design write-up lives in `docs/location-diagram.md`; this is
what was done and why.

**Data.** New migration `20260730000001_add_layout_coordinates_to_plants` adds nullable
`layout_x`/`layout_y` floats. Stored **normalized 0.0–1.0 as the chip's centre**, not pixels, so a
layout arranged on a phone reads the same on a desktop and the canvas can be any width.
`Plant#layout_placed?` requires both columns; range validation 0..1 allowing nil.
`Plant#clear_layout_on_location_change` (before_validation) drops the pair when `location_id`
changes — and because `plants#bulk_set_location` relocates with `update_all` and skips callbacks, it
now clears the columns in the same statement. That pairing is the one thing here likely to be
re-broken later, so it went into CLAUDE.md's Data-layer traps as well as the doc.

**Server.** `PATCH /locations/:id/layout` → `LocationsController#update_layout` (route named
`layout_location`; the action can't be `layout` — collides with Rails' layout machinery). Payload is
`{positions: [{id, x, y}]}`, batched. Ids are filtered through `@location.plants`, so a plant from
another project *or another location* is silently ignored; coordinates are clamped server-side.
Writes use `update_columns` rather than `update!` **on purpose**: a chip move must not 500 because
the plant carries an unrelated validation error (a duplicate `uid` from an import), and the
coordinates are already clamped. `show` derives the legend from the plants actually standing in the
location (`@diagram_plants.flat_map(&:plant_groups)` tallied; recipes behind `use_fertilizers`).
`index` loads `@layout_points` in a **second query** — the main relation is grouped for the
plant-count ordering, so plant rows can't be preloaded onto it.

**Client.** New `location_diagram_controller.js`: pointer events (one path for finger and cursor),
4px drag threshold so a tap isn't a fling, canvas↔tray drag as the place/unplace gesture, chip
half-size clamping so nothing hangs off the edge, debounced batched PATCH, arrow-key nudge, optional
photo backdrop, legend click-to-highlight. Dragging is gated on "Arrange" mode, which only renders
for `can_edit?` (and `editableValue` gates it client-side too). Followed the codebase idiom of
`.bind(this)` in `connect()` rather than class fields, matching `card_fields_controller`.

**Views/CSS.** `locations/_diagram` + `_diagram_chip` partials on show; new
`app/assets/stylesheets/locations.sass` (re-declares the palette, as each sass file here does). Index
cards get a read-only mini-diagram in the thumbnail slot when a layout exists, keeping the photo as a
faint backdrop, and falling back to the previous card exactly when it doesn't.

**Tests:** 10 new controller tests (store/clamp/unplace, cross-project reject, wrong-location reject,
other-project location 404, viewer can view but not save, index mini-diagram present/absent, show
chip count incl. archived exclusion), 4 Plant model tests, 3 Location model tests. New test helper
`viewer_of_project_one` builds a view-only collaborator inline — there are no collaborations
fixtures, and adding one would break the alphabetical FK load order.

**Needs user:** `bin/rails db:migrate` then `bin/rails test`. (Not run here — I can't run
`bin/rails`.) Nothing has exercised the drag interaction in a browser yet.

## 2026-07-31 — Location diagram: chip uids + desktop vertical fit (#114 follow-up)

**Chip labels.** Two plants of the same species rendered as two identical "Fern" chips. The label
now leads with the uid (`#37 Fern`) via a muted `.diagram-chip-uid` span; chip width 4.5rem → 5rem
(mobile 3.6 → 4.1rem) so the common case doesn't ellipsis. `plant.label` was already the `title`,
so the full text was always one hover away — this just surfaces it.

**Desktop space.** Goal was the whole diagram card inside one laptop screen without scrolling.
Four changes:

1. `_diagram` gained a `.diagram-body` wrapper splitting into `.diagram-stage` (canvas + status)
   and `.diagram-side` (tray + legend). At ≥1000px that's a 2-column grid — the tray and legend
   move off the vertical stack into a side rail. Below 1000px it's a flex column, i.e. the old
   order. No JS change needed: the controller finds its targets anywhere in scope, and
   `isOverTray` is rect-based so the tray works as a drop zone wherever it sits.
2. Canvas is height-driven above 750px: `aspect-ratio: auto` + `height: var(--diagram-canvas-h)`
   = `clamp(14rem, 46vh, 26rem)`. Legitimate because coordinates are normalized — a shorter, wider
   frame is still a faithful layout. The card is capped at 1200px so the frame can't go
   letterbox-thin on an ultrawide. Mobile keeps 4/3.
3. `show.html.erb`: the `.info-card` moved below `#location-supplies` (user's call) — the diagram
   now leads the page, details sit past the fold.
4. `.location-photo` thumb capped at 9rem (was the shared 18rem with tanks). It sat directly above
   the diagram and was the single biggest thing pushing it off screen; the diagram can already
   show the same photo as its backdrop.

Rail scrolls internally (`max-height: var(--diagram-canvas-h)`) so a long legend can't outgrow the
canvas, and a `:not(:has(.diagram-side > *:not([hidden])))` rule gives the rail's width back to the
canvas when there's nothing unplaced and no legend.

**Verification:** templates compile under the Rails ERB handler, both sass files compile (`:has()`
survives sassc). Not run: `bin/rails test`, and no browser check of the new grid.

**Correction, same day.** The side rail held the tray as well as the legend, which made the tray
two chips wide with heavy scrolling — bad, since the tray is the surface you drag *from*. Tray
moved back full-width under the canvas (~10 chips a row, `max-height: 10rem` then it scrolls
itself), rail now holds the legend only. While the tray is showing,
`:has(.diagram-tray:not([hidden]))` drops `--diagram-canvas-h` to `clamp(11rem, 31vh, 19rem)` so
the tray's space comes out of the canvas, not off the bottom of the page; the canvas transitions
its height so entering Arrange glides rather than jumps. The legend is now omitted server-side when
empty and the grid keys off `.diagram-body:has(.diagram-side)`, which replaced the earlier
`:not(:has(...))` collapse hack.

**Widescreen, same day.** Dropped the `max-width: 1200px` on `.location-diagram` — the card now
runs the full content width so a wide monitor is actually used, and the canvas takes whatever the
rail doesn't. Clamp maxima raised (`26rem` → `30rem`, tray-open `19rem` → `22rem`) so a tall
widescreen gets a less letterboxed frame; the `vh` terms still do the "one screen" work.

## 2026-07-31 (cont.) — Drag ghost + recipe-grouped tray

**Drag glitch.** Reported: dragging a chip out of "Not placed yet" made a chip appear on the canvas
before the pointer got there. Cause was in `_onPointerMove` — at the 4px threshold a tray chip was
`appendChild`-ed into the canvas and positioned via `pointToCanvas`, which *clamps* to the canvas,
so a pointer still down in the tray parked it on the canvas's bottom edge. Fixed by never changing
containers mid-drag: `.is-dragging` now sets `position: fixed` (z-index 900 — above the header at
100, below modals at 1000) and the controller writes viewport px into `left`/`top`, converting to
normalized canvas coordinates only in the new `place()` on pointerup. `pointToCanvas` is gone,
`_onPointerCancel` just restores the two inline strings, and the drag now preserves the grab offset
so a chip grabbed by its edge doesn't snap under the cursor. Checked first that no ancestor
(`html`/`body`/`main`/`section#primary`) has a transform or filter that would make `fixed` resolve
against something other than the viewport.

**Tray grouped by fertilizer recipe.** Keyed on the *primary* recipe (`plant.recipe`) so a plant on
several recipes files once; `:recipe` added to the show-action `includes`. Behind `use_fertilizers`,
and the flat tray is kept verbatim when no plant here has a recipe. Buckets are rendered for every
recipe in the location rather than only the unplaced ones, because `unplace()` needs a group to
return a chip to (`trayBucketFor` matches `data-recipe-group` against the first id in the chip's
`data-recipe-ids`); empty ones are `hidden` and `refreshEmptyStates` maintains that. `.legend-swatch`
hoisted out of `.legend-chip` so the tray headings can reuse it. Tray cap 10rem → 12rem and the
tray-open canvas 31vh → 28vh to pay for the heading rows.

**Verification:** templates + sass compile, divs balance, controller parses. Still not run:
`bin/rails test`; no browser check of the new drag behaviour.

**Full-height rail + resizable areas.** `.diagram-side` now spans the whole body height rather than
stopping at the canvas: grid items stretch (dropped `align-items: start`) and the legend inside is
`position: absolute; inset: 0`, so it fills the rail but contributes nothing to the row's sizing —
a long legend scrolls in place instead of stretching the row and leaving dead space beside the
canvas.

Canvas and tray both take CSS `resize: vertical` above 750px (each already had a non-visible
`overflow`, the prerequisite). The tray moved from `max-height: 12rem` to a definite
`height: var(--diagram-tray-h)` (10rem) — a max-height caps growth, so the handle could only ever
shrink it. Removed the canvas height `transition` added earlier: it fights the resize handle. With
the tray now a fixed 10rem the tray-open canvas went back to 31vh.

Heights persist per device via localStorage. The trick that keeps it honest: a resize handle writes
an *inline* height, and CSS-driven changes never do — so the controller persists
`style.height` and automatically ignores the tray-open shrink and window resizes. `ResizeObserver`
is the (debounced, read-only) trigger; restore is skipped below 751px where a pixel height would be
wrong.

## 2026-07-31 — Cross-user project carryover on login (waterings#new test failure)

`WateringsControllerTest#test_no-pins_project_falls_back_to_smart-suggestion_chips` 302'd to
`/plants`. Root cause was in `login`, not the test: `reset_session` doesn't touch
`cookies.encrypted[:project_id]`, so the setup sign-in as `users(:one)` left project one selected
when the test signed in as `users(:two)` — `auto_select_project` returns early whenever
`current_project` is present, so user two browsed project one and `authorize_editor` bounced them.
Same bug in production on a shared browser, and after a non-advanced guest merge the carried-over
cookie points at a *destroyed* project.

Fixed with `discard_foreign_project_selection(user)` in `ApplicationController#login`: delete the
cookie and nil `Current.project` unless the incoming user owns or collaborates on it. Membership
check rather than an unconditional clear, because the advanced-mode branch of `merge_guest!`
reassigns the guest's projects to the target user, who should stay in the project they were working
in. Safe because all eight `login` callers already follow up with `auto_select_project` or
`set_current_project`. Writing the cookie after `delete` in the same request wins (`[]=` drops the
key from `@delete_cookies`), so the `set_current_project` callers are unaffected.

The four sibling cross-project tests (`equipment`, `water_changes`, `feeding_instructions`,
`maintenance_logs`) still assert `redirected_to plants_url` — they now reach it through
`set_tank`'s scoped `find` raising `RecordNotFound` instead of through the authorize check.

**Verification:** `bin/rails test test/controllers/waterings_controller_test.rb` and
`bin/rails test test/controllers` — no failures (run by Jef). Doc note added to
`docs/auth-accounts.md`.

## 2026-07-31 — Plant show: location value links to its show page

The 📍 Location row in `app/views/plants/_plant.html.erb` rendered `plant.location` as plain text
while the sibling Recipes row already linked through. Wrapped it in
`link_to plant.location, location_path(plant.location)`, matching the recipe row's unstyled-link
pattern.

No `data: { turbo_frame: "_top" }` needed here — that gotcha applies to links inside
`turbo-frame#plants-results` on the index; `plants/show.html.erb` renders the partial at top level.
The partial is rendered only from the plant show page (checked), so no public/share-token view is
affected by pointing at an authenticated route.

Added `test/controllers/plants_controller_test.rb` "show links the location to its show page"
(`assert_select` on the href). Not yet run — needs `bin/rails test test/controllers/plants_controller_test.rb`.

## 2026-07-31 — Cloned prod photo renders blank locally (stale variant records)

Symptom: after `AUTOFAUNA_SYNC_USER_EMAIL=... ./util/clone_production_db_to_local.sh --storage`, a
newly-uploaded photo on plant 19 showed a blank image locally.

Ruled out in order: original file *was* synced and intact (8247490 bytes, md5 matched the blob
checksum); libvips 8.12.1 present and `ruby-vips` loads; `ImageProcessing::Vips.resize_to_limit`
succeeded on that exact file. So neither the sync nor the image pipeline was at fault.

Root cause: `track_variants` is on (`load_defaults 7.0`), so the pg dump carries
`active_storage_variant_records` from production. Rails sees a tracked variant, considers it already
processed, and serves a URL to a variant file that `list_user_storage_paths.rb` never transferred —
it listed originals only, on the assumption (stated in its header and in `docs/deployment.md`) that
variants regenerate on demand. They don't, once tracked. 12 of 94 variant records pointed at missing
files; the other 82 survived from an earlier full `--storage` sync, which is why only the new photo
looked broken.

Fixes:
- `util/list_user_storage_paths.rb` now emits originals **plus** their tracked variant blobs.
- `util/clone_production_db_to_local.sh` aborts if the path list comes back empty (an unknown email
  made the runner abort, leaving rsync to "succeed" having copied nothing).
- `docs/deployment.md`: replaced the "variants regenerate" claim; noted `AUTOFAUNA_SYNC_USER_EMAIL`
  is the app login and that `user.plants` is `through: :projects` on `owner_id` (collaborator-only
  projects are excluded).

Unblocked the existing clone without re-downloading by deleting the 12 stale variant records
(+ their attachment/blob rows) so Active Storage rebuilds them on next render. Verified 0 of the
remaining 82 dangle. No app code touched; nothing to test with `bin/rails`.

### Follow-up same day — second cause: non-Plant attachments never synced

Re-running the clone with the variant fix cut missing variant files from 12 to 5, but images were
still blank. The remaining 5 (plus 2 originals) belonged to `Location#picture`, not plants:
`list_user_storage_paths.rb` filtered on `record_type: "Plant"`, while `HasPicture` also attaches
`:picture` to **Location** and **Tank**. Those originals had never been transferred by targeted mode
at all — the first report just surfaced the plant photo, so the location photos went unnoticed.

Generalised the script from `user.plants` to a `record_scopes` map over every attachable model
scoped to `user.projects` (Plant / Location / Tank), with a comment that new attachable models must
be registered there. Query now emits 149 keys vs 139.

Cleared the 5 stale Location variant records so they rebuild locally; the 2 missing originals still
need fetching from prod (targeted rsync, or just re-run the clone script now that it's fixed).
