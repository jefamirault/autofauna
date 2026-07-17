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
