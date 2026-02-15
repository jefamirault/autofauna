# Agent Log

Current session log. Previous logs archived in `agent_log/`.

---

## 2026-02-15 — Watering Recipes, Batches, Sources & TDS Tracking

**Goal:** Add recipe-based watering system with sources (ingredients), recipes (compositions), batches (specific mixes at target TDS), and integration into plants and waterings.

**Workflow:** User creates Sources (e.g. "FloraGro"), composes Recipes from those sources with amounts, then mixes Batches at a target TDS. Plants get a default recipe for filtering. When watering, the user selects a recipe/batch and the TDS is recorded. Quick-water carries forward the last batch/recipe/TDS.

**Status:** Complete — awaiting `bin/rails db:migrate`

### Migrations (4 files)
- `db/migrate/20260215100000_create_recipe_sources.rb` — recipe_sources table (project_id, name, tank_id, description; unique on [project_id, name])
- `db/migrate/20260215100001_create_recipes.rb` — recipes table (project_id, name, description; unique on [project_id, name])
- `db/migrate/20260215100002_create_recipe_ingredients_and_recipe_batches.rb` — recipe_ingredients join table (recipe_id, recipe_source_id, amount, units, position) + recipe_batches table (project_id, recipe_id, tds, volume, volume_units, mixed_on, notes, active)
- `db/migrate/20260215100003_add_recipe_fields_to_waterings_and_plants.rb` — adds recipe_id to plants, tds/recipe_batch_id/recipe_id to waterings

### Models (4 new, 4 modified)
- `app/models/recipe_source.rb` — belongs_to project/tank, has_many recipe_ingredients/recipes, validates name uniqueness scoped to project
- `app/models/recipe.rb` — belongs_to project, has_many ingredients/sources/batches/plants/waterings, accepts_nested_attributes_for :recipe_ingredients, ransackable by id/name
- `app/models/recipe_ingredient.rb` — belongs_to recipe/recipe_source, validates uniqueness of source per recipe
- `app/models/recipe_batch.rb` — belongs_to project/recipe, has_many waterings, enum volume_units matching Watering, validates tds > 0, scope :active, `to_s` → "Recipe @ 400ppm", `label` → "Recipe @ 400ppm (Feb 15)"
- Modified `app/models/plant.rb` — added `belongs_to :recipe, optional: true`, recipe_id to ransackable_attributes, recipe to ransackable_associations
- Modified `app/models/watering.rb` — added `belongs_to :recipe_batch/:recipe, optional: true`, before_validation to auto-set recipe from batch
- Modified `app/models/project.rb` — added has_many recipe_sources/recipes/recipe_batches
- Modified `app/models/tank.rb` — added has_many recipe_sources

### Routes
- `config/routes.rb` — added `resources :recipe_sources`, `resources :recipes`, `resources :recipe_batches` (with `collection { get :for_recipe }` JSON endpoint)

### Controllers (3 new, 2 modified)
- `app/controllers/recipe_sources_controller.rb` — standard CRUD scoped to current_project
- `app/controllers/recipes_controller.rb` — CRUD with nested attributes for recipe_ingredients
- `app/controllers/recipe_batches_controller.rb` — CRUD + `for_recipe` action returning JSON for dynamic batch dropdown
- Modified `app/controllers/waterings_controller.rb` — added tds/recipe_batch_id/recipe_id to new action pre-population and strong params
- Modified `app/controllers/plants_controller.rb` — added recipe_id to strong params, built @recipe_filters for index, carry forward recipe/batch/tds in water action

### Views (15 new, 6 modified)
- `app/views/recipe_sources/` — index, _form, new, edit, show (UI label: "Source")
- `app/views/recipes/` — index, _form (nested ingredient rows via nested-form Stimulus controller), new, edit, show
- `app/views/recipe_batches/` — index (grouped active/inactive), _form, new, edit, show (UI label: "Batch")
- Modified `app/views/waterings/_form.html.erb` — recipe dropdown, dynamic batch dropdown (Stimulus), TDS field
- Modified `app/views/plants/_form.html.erb` — recipe dropdown after location
- Modified `app/views/plants/index.html.erb` — Ransack recipe filter dropdown with auto-submit
- Modified `app/views/plants/_plant_row.html.erb` — shows recipe name, carries forward recipe_batch_id/recipe_id/tds in quick-water link
- Modified `app/views/plants/show.html.erb` — displays plant's default recipe
- Modified `app/views/plants/_timeline.html.erb` — shows TDS, recipe, batch on watering entries

### Stimulus Controllers (2 new)
- `app/javascript/controllers/watering_recipe_controller.js` — on recipe change fetches `/recipe_batches/for_recipe?recipe_id=X` to populate batch dropdown; on batch select auto-fills TDS
- `app/javascript/controllers/nested_form_controller.js` — reusable add/remove rows for nested attributes using `<template>` tag with NEW_RECORD placeholder

### Navigation & Styling
- `app/views/layouts/application.html.erb` — sidebar shows Recipes/Batches/Sources sub-items when on plants/waterings/recipe controllers
- `app/helpers/application_helper.rb` — header_config routes recipes/recipe_batches/recipe_sources to waterings header
- `app/assets/stylesheets/shared.sass` — added recipe controllers to label/form/settings-card styling; added .nested-row, .recipe-filter, .watering-tds/.watering-recipe/.watering-batch styles

---

## 2026-02-15 — Fix Recipe/Batch Pre-population on Plant Show Page

**Goal:** Fix water buttons on plant detail page to pre-populate recipe, batch, and TDS fields from last watering (matching behavior already working on index page).

**Problem:** The "Click to Water" button on the plant show page only passed `volume`, `units`, and `notes` parameters, omitting `recipe_id`, `recipe_batch_id`, and `tds`. This required users to manually re-select the recipe and batch they used last time when watering from the detail page.

**Root Cause:** The `_plant.html.erb` partial and `show.html.erb` view had incomplete parameter lists in their `plant_water_path` links, while the working `_plant_row.html.erb` (index page) included all necessary parameters.

**Solution:** Added missing parameters (`recipe_batch_id`, `recipe_id`, `tds`) to three water button links:
1. SVG icon button in info card (`_plant.html.erb` line 4)
2. First "💧 New watering" link before timeline (`show.html.erb` line 64)
3. Second "💧 New watering" link after timeline (`show.html.erb` line 70)

All three now match the pattern used on the index page and use safe navigation operators (`&.`) to handle plants without previous waterings.

**Files Modified:**
- `app/views/plants/_plant.html.erb` — added `recipe_batch_id`, `recipe_id`, `tds` to water icon link
- `app/views/plants/show.html.erb` — added all last watering parameters to both "New watering" links (lines 64, 70)

**Status:** Complete — ready for testing
