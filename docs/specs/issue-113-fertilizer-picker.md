# Spec: Unified fertilizer picker on the watering form (#113)

**Issue:** [#113 — Watering form: single recipe/fertilizer picker with pinned shortlist + searchable "More…"](https://github.com/jefamirault/autofauna/issues/113)

Replace the three selects — Source (water type), Recipe, Batch — in the watering form's **Mix**
section with a single picker: a row of tappable chips for a configured shortlist, plus a "More…"
control that expands to a searchable list of every source and recipe in the project. The picker
still populates the same three columns (`recipe_source_id`, `recipe_id`, `recipe_batch_id`), so
nothing downstream changes.

---

## 1. Current state (grounding)

- **Form:** `app/views/waterings/_form.html.erb:28-66`. Gated by
  `feature_enabled?(:use_fertilizers)` and split into `has_sources` / `has_recipes` branches.
  Three inputs: `collection_select :recipe_source_id`, `collection_select :recipe_id`, and a
  hand-rolled `<select>` for batch (server-populated on edit, JS-populated on change).
- **JS:** `watering_recipe_controller.js` handles source⇄recipe mutual exclusion
  (`sourceChanged`), fetches batches from `for_recipe_recipe_batches_path` (`recipeChanged`), and
  autofills TDS from the chosen batch (`batchChanged`). It also owns the volume/TDS
  progressive-disclosure toggles, which stay.
- **Dead code:** the `unifiedBatchSelect` / `recipeIdHidden` targets and `unifiedBatchChanged()`
  in that controller are referenced by **no view** (leftover from an earlier attempt). Remove them
  as part of this work.
- **Server:** `watering_params` already permits all three ids
  (`app/controllers/waterings_controller.rb:136`) — **no write-path changes needed**.
  `Watering#set_recipe_from_batch` (before_validation) already syncs `recipe_id` from a batch.
- **Render sites:** the form renders only on `waterings#new` and `waterings#edit`
  (`new.turbo_stream.erb` replaces a plant row, not the form). `Plant#quick_water!`
  (single/group/location bulk watering) bypasses the form entirely — unaffected.
- **Prefill paths that must round-trip:** `waterings#new` seeds the model from query params
  (`waterings_controller.rb:28-29`), and `waterings#edit` loads a persisted record. Either may
  carry a source/recipe/batch that is *not* on the shortlist.
- **Existing patterns to build on:**
  - `shared/_smart_select` + `smart_select_controller` — suggestion chips (`.suggestion-chip`,
    `.selected` fills the section color) + a `<details>` "Show all" fallback. The picker follows
    this visual language but needs its own controller (multi-field, mixed item types, search,
    batch resolution).
  - `SmartSuggestions` (`app/services/smart_suggestions.rb`) already ships **unused** scorers
    written for this feature: `watering_recipe_scorer(plant)` (plant's assigned recipes first,
    then recently used), `recipe_scorer`, `batch_scorer_for_recipe`. Use them for the no-pins
    fallback.
  - `fertilizer_icon(recipe, size:)` helper (from #112) — colored test-tube SVG, `:small` = 18px.

---

## 2. Data model

Migration (one, two columns):

```ruby
add_column :recipes, :pinned, :boolean, default: false, null: false
add_column :recipe_sources, :pinned, :boolean, default: false, null: false
```

- `scope :pinned, -> { where(pinned: true) }` on both models.
- Permit `:pinned` in `recipes_controller` and `recipe_sources_controller` strong params.
- Checkbox on both edit/new forms (Recipe form under Basics; RecipeSource form near name):
  label “Pin to watering shortcuts” with a hint line (“Pinned items appear as one-tap choices on
  the watering form”).
- Ordering of pinned chips: alphabetical by name. (A `position` column / drag-to-pin is deferred —
  see Out of scope.)

No new columns on `waterings`.

---

## 3. UX

The **Mix** section keeps its `form-section-label` eyebrow and replaces its body with the picker.

### 3.1 Default (collapsed) state — chip row

One row of `.suggestion-chip` buttons (wrapping, same look as the plant form's smart-select):

1. **None** — plain water. Selected state when all three ids are blank.
2. **Pinned sources** — 💧 + name (sources have no color/icon; use the droplet emoji).
3. **Pinned recipes** — `fertilizer_icon(recipe)` + name.
4. **Current selection, if unpinned** — on edit/prefill round-trip, the selected source or recipe
   is always rendered as a chip even when not pinned, so the state is visible and re-selectable.
5. **More…** — opens the expanded panel (below).

**Fallback when nothing is pinned** (fresh projects, pre-adoption): show smart suggestions
instead — `SmartSuggestions.watering_recipe_scorer(watering.plant)` over the project's recipes,
limit 3, plus all sources if the project has ≤ 2, and always the More… chip. Pinned and suggested
chips never mix: pins, once configured, fully define the shortlist.

Exactly one chip is visually `.selected` at all times (None counts).

### 3.2 Expanded state — search over everything

Tapping **More…** reveals an inline panel (not a modal) directly under the chip row:

- A search `text_field` (placeholder “Search sources & recipes…”), autofocused on open.
- A scrollable list (`max-height` ~14rem) with two labeled groups: **Sources** then
  **Fertilizers**. Each row: icon (💧 / `fertilizer_icon`) + name. Rows are buttons.
- Search filters both groups client-side by case-insensitive substring; group headers hide when
  their group has no matches.
- Selecting a row: applies the selection, marks/creates the matching chip as selected, collapses
  the panel, clears the search.
- More… toggles the panel closed as well.

The whole list is **server-rendered into the DOM** (hidden until expanded) — no fetch, no new
endpoints. A project's sources + recipes are at most dozens of rows; this also makes edit
round-trip and Capybara testing trivial. Consequently the `for_recipe` / `for_project` JSON
endpoints and the controller's `url` / `projectUrl` values become unused by this form — remove
them if nothing else calls them (grep first; `for_project` is currently referenced only by this
form's `data` attributes).

### 3.3 Selection semantics (what the hidden fields do)

Three hidden fields carry the state: `watering[recipe_source_id]`, `watering[recipe_id]`,
`watering[recipe_batch_id]`.

| Action | source_id | recipe_id | batch_id | TDS side-effect |
|---|---|---|---|---|
| None | ∅ | ∅ | ∅ | — |
| Pick a source | id | ∅ | ∅ | — |
| Pick a recipe | ∅ | id | auto (see 3.4) | autofill (see 3.4) |

Source and recipe remain mutually exclusive, exactly like today's `sourceChanged` behavior.

### 3.4 Batch resolution (recipe picked)

Each recipe's active batches are embedded server-side (JSON `data-batches` attribute on the
recipe's chip/row: `[{id, label, tds}]`, ordered `mixed_on: :desc`; on the edit form the
currently-selected batch is included even if it has since been deactivated, labeled “(inactive)” —
today's form silently drops it, which would clear `recipe_batch_id` on save).

- **0 active batches:** `recipe_batch_id` stays blank; TDS autofill falls back to
  `recipe.default_tds` (matching the intent of the dead `unifiedBatchChanged` code).
- **1 active batch:** auto-select it silently.
- **≥ 2 active batches:** auto-select the most recent, and reveal a small secondary **Batch**
  `<select>` under the chip row (options = that recipe's batches, `batch.label`) so the user can
  override. Hidden again whenever the selection isn't a multi-batch recipe.

TDS autofill (batch `tds`, else recipe `default_tds`) reuses today's behavior: set the TDS field
and un-hide the TDS container. Since those targets belong to `watering-recipe`, the picker
dispatches an event rather than reaching in — see 4.3.

### 3.5 Fallbacks (unchanged behavior)

- `use_fertilizers` off, or project has zero sources **and** zero recipes → the Mix section
  renders nothing, exactly as today (`has_recipes || has_sources` guard stays).
- Only sources, or only recipes → picker renders whichever exist; empty groups are omitted.

---

## 4. Implementation plan

### 4.1 Partial

New `app/views/waterings/_fertilizer_picker.html.erb`, rendered from `_form.html.erb` in place of
lines 33–65 (inside the existing `has_recipes || has_sources` guard). Locals: `form`, `watering`.
It renders the chip row, the three hidden fields, the hidden search panel, and the hidden batch
select. All collections come from `current_project` (server-rendered ⇒ cross-tenant scoping is
enforced at render time, per the multi-tenant invariant).

### 4.2 Stimulus: `fertilizer_picker_controller.js` (new, one controller per the issue)

Targets: `sourceIdField`, `recipeIdField`, `batchIdField`, `chip`, `panel`, `searchInput`,
`listRow`, `groupHeader`, `batchRow`, `batchSelect`.
Actions: `pick` (chip or list row — reads `data-kind="source|recipe|none"` + `data-id` +
`data-batches`), `togglePanel`, `search` (input), `batchChanged`.
On `connect()`, derive the selected state from the hidden field values (server sets them from the
model), so new/edit/param-prefill all round-trip through one code path.

When a selection implies a TDS value it dispatches
`this.dispatch("tds", { detail: { tds } })` → handled on the form element by the existing
controller: `data-action="fertilizer-picker:tds->watering-recipe#applyTds"` (new small method =
current `batchChanged` body: set field + `showTds()`).

### 4.3 `watering_recipe_controller.js` cleanup

Delete `sourceChanged`, `recipeChanged`, `batchChanged`, `unifiedBatchChanged`, and the
`sourceSelect/recipeSection/recipeSelect/batchSelect/unifiedBatchSelect/recipeIdHidden` targets;
add `applyTds(event)`. The controller keeps volume/TDS disclosure only (consider renaming to
`watering-measurements` later; not required).

### 4.4 Styles

In `shared.sass` next to the existing `.smart-select` rules: `.fertilizer-picker` — chip row
reuses `.suggestion-chip` (icon + text alignment tweak), panel (bordered card, search input,
`max-height` scroll list, group headers as mini eyebrows), batch row. Section color via
`var(--section-color-start)` so it inherits watering blue like the rest of the form.

### 4.5 i18n

New keys under `waterings.form.picker_*` (e.g. `none` reuses existing, `more`, `search_placeholder`,
`sources`, `fertilizers`, `batch`) in **all** locale files; `recipes.form.pinned_label` /
`recipe_sources.form.pinned_label` + hint. `waterings.form.none_use_recipe` becomes unused — remove.

### 4.6 Hardening (adjacent, small)

`watering_params` permits raw `recipe_id`/`recipe_source_id`/`recipe_batch_id`, and `Watering` has
no project-consistency validation — a crafted POST can attach another project's recipe today
(pre-existing, form UI unaffected). While touching this area, add to `Watering`:

```ruby
validate :mix_belongs_to_plant_project  # recipe/source/batch project_id must == plant.project_id, when present
```

This upholds the "mass-assignment must filter to the project" invariant server-side. Verify
`quick_water!` carry-forward still passes (it copies ids from a same-project watering, so it will).

---

## 5. Testing

- **Model:** `pinned` defaults false; `pinned` scope; `Watering` project-consistency validation
  (accepts same-project ids, rejects other-project recipe/source/batch — fixtures from project
  `two`).
- **Controller:** `recipes#update` / `recipe_sources#update` persist `pinned`; `waterings#create`
  with `recipe_id` + `recipe_batch_id` and with `recipe_source_id` writes identical data to today
  (fidelity acceptance criterion); cross-project id rejected.
- **System (Capybara, JS):**
  1. Default state shows None + pinned chips only; unpinned recipe absent.
  2. More… → search narrows list → picking a recipe with one active batch sets hidden
     `recipe_id` + `recipe_batch_id` and autofills TDS; save and assert persisted columns.
  3. Recipe with two active batches reveals the batch select, defaulted to most recent;
     overriding persists the chosen batch.
  4. Picking a source clears recipe/batch; picking None clears all three.
  5. Edit round-trip: watering with an unpinned recipe + inactive batch shows a selected chip and
     the “(inactive)” batch option; saving without changes preserves all three ids.
- **Fallback:** project without `use_fertilizers` (or no sources/recipes) renders no Mix section
  (existing tests should still pass).

---

## 6. Acceptance criteria (from the issue)

- [ ] One input replaces the Source/Recipe/Batch selects on the watering form.
- [ ] Default state shows only the user's configured shortlist (pins; smart suggestions before
      any pins exist).
- [ ] "More…" reveals search across all sources and recipes.
- [ ] Created waterings have the same `recipe_source_id`/`recipe_id`/`recipe_batch_id` data
      fidelity as today (incl. TDS autofill).
- [ ] Works on `waterings#new` and `waterings#edit` (the only places the form renders); param
      prefill and edit both round-trip into the picker.
- [ ] Pinning configurable from Recipe and RecipeSource forms.

## 7. Out of scope

- Drag-to-pin / manual ordering of the shortlist (`position` column) — pinned chips are
  alphabetical for now.
- Any change to `quick_water!` / bulk-watering flows (no form involved).
- Redesign of the batch concept or batch CRUD; `for_recipe`/`for_project` endpoint removal is
  cleanup-only if truly unreferenced.

## 8. Open questions

1. Shortlist fallback limit (spec says 3 suggested recipes + ≤2 sources) — tune after use?
2. Should picking a **source** ever autofill TDS (e.g. a tank's last water test)? Deferred.
