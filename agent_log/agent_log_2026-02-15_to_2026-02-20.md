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

---

## 2026-02-15 — Convert Recipe Dropdown to Toggleable Filter Buttons

**Goal:** Replace the recipe dropdown filter on plants index with toggleable buttons matching the location filter UI pattern, enabling client-side filtering with AND logic for combined location + recipe filtering.

**Problem:** Recipe dropdown was inconsistent with location filter UI/UX and required server roundtrips for filtering.

**Solution:** Replaced server-side dropdown with client-side toggleable buttons that work exactly like the location filter, with counts, collapse/expand for >4 items, and AND logic when both filters are active.

**Implementation:**

### 1. Plant Card Data Attributes
- `app/views/plants/_plant_row.html.erb` — added `data-recipe-id` attribute (using "none" for plants without recipes)

### 2. Controller Recipe Filter Building
- `app/controllers/plants_controller.rb` — replaced simple recipe list with count-based filter buttons (lines 38-43):
  - Query recipe counts from filtered plants
  - Include "No Recipe (N)" button when plants without recipes exist
  - Format matches location filters: "Recipe Name (5)"

### 3. View Replacement
- `app/views/plants/index.html.erb` — replaced dropdown (lines 41-48) with:
  - collapsible-filters controller wrapper
  - Recipe filter button container with location-filter targets
  - Buttons with recipe-id, recipe-count, and click handler
  - Show more/less toggle for >4 recipes

### 4. JavaScript Controller Extension
- `app/javascript/controllers/location_filter_controller.js`:
  - Added `recipeFilterButton` and `recipeButtonContainer` targets
  - Initialized `selectedRecipes` Set in connect()
  - Added `toggleRecipeFilter()` — toggle recipe in selection set
  - Added `applyRecipeFilter()` — update UI and filter plants
  - Added `updateRecipeButtonStates()` — manage active classes
  - Added `reorderRecipeButtons()` — active buttons first, sorted by count
  - Modified `filterPlants()` — AND logic: show plants matching BOTH location and recipe filters (or all if none selected)
  - Modified `updateResultsCount()` — count visible plants considering both filters

### 5. CSS Styling
- `app/assets/stylesheets/plants.sass` — added `.recipe-filters` and `.recipe-filters-toggle` styles (lines 96-119), matching location filter patterns

### 6. Removed Old Styles
- `app/assets/stylesheets/shared.sass` — removed `.recipe-filter` dropdown styles (lines 963-972)

### 7. Locale Strings
- `config/locales/en.yml` — added `filter_by_recipe: "Filter by recipe"`, `no_recipe: "No Recipe"`
- `config/locales/es.yml` — added `filter_by_recipe: "Filtrar por receta"`, `no_recipe: "Sin receta"`

**Behavior:**
- Recipe buttons appear with counts (e.g., "Bloom Recipe (5)")
- Clicking toggles filter (no page reload)
- Active buttons get blue background, move to front, sort by count
- Collapse/expand works when >4 recipes
- Combined filtering: location + recipe filters = AND logic (only plants matching both)
- "No Recipe" button appears when applicable
- Results count updates correctly with filters active
- Display mode switching preserves filter state
- Search + filters work together correctly

**Status:** Complete — ready for testing at `/plants`

---

## 2026-02-15 — Plants Page Enhancement: Colors, Watering Status Filters, UX Improvements

**Goal:** Add user-assignable colors to Locations/Recipes, watering status filters (Overdue/Needs Water/Scheduled), collapsible groups, search clear button, client-side display mode switching, improved filter sorting, and enhanced result messaging.

**Features:**
1. **Color coding**: Users can assign colors to Locations and Recipes; colors appear on filter buttons and group headers
2. **Watering status filters**: New filter buttons for Overdue/Needs Water/Scheduled watering states
3. **Improved filter UX**: Pre-sort by count (descending), maintain client-side display mode switching
4. **Search clear button**: Quick X button to clear search without manual deletion
5. **Collapsible groups**: Location groups with colored headers and localStorage persistence
6. **Enhanced messaging**: Dynamic result text that reflects active filters/search
7. **Client-side mode toggle**: Switch between watering/location display without page reload

**Implementation Details:**

### Database Migrations (2 files)
- `db/migrate/20260215200000_add_color_to_locations.rb` — adds color column to locations (default: #0E487B)
- `db/migrate/20260215200001_add_color_to_recipes.rb` — adds color column to recipes (default: #7B1FA2)

### Models Updated (2 files)
- `app/models/location.rb` — added color validation (hex format), hex_color method, color to ransackable_attributes
- `app/models/recipe.rb` — added color validation (hex format), hex_color method, color to ransackable_attributes

### Controllers Updated (3 files)
- `app/controllers/plants_controller.rb` — filter data now uses hash format with {name, id, count, color}, pre-sorted by count descending, watering_status_groups built for filtering, location grouping includes colors
- `app/controllers/locations_controller.rb` — added :color to strong params
- `app/controllers/recipes_controller.rb` — added :color to strong params

### Views Updated (4 files)
- `app/views/plants/index.html.erb` — search clear button in header, display mode as Stimulus buttons, watering status filter section, filter buttons use color data attributes and CSS variables, location groups now collapsible with colored headers, new Stimulus values for filtered result templates
- `app/views/plants/_plant_row.html.erb` — added data-watering-status attribute for filtering
- `app/views/locations/_form.html.erb` — added color picker field with helper text
- `app/views/recipes/_form.html.erb` — added color picker field with helper text

### JavaScript Controllers (2 files)
- `app/javascript/controllers/collapsible_group_controller.js` — NEW controller for collapsible location groups with localStorage persistence
- `app/javascript/controllers/location_filter_controller.js` — MAJOR UPDATE:
  - New targets: searchInput, clearSearchBtn, wateringStatusButton, wateringStatusContainer, wateringGroup, groupCount
  - New values: resultsFilteredTemplate, resultsFilteredSearchTemplate
  - New methods: switchDisplayMode (client-side mode toggle), toggleWateringStatusFilter, clearSearch, updateSearchClearButton, updateDisplayMode, updateGroupCounts
  - Updated methods: filterPlants (now includes watering status filtering), updateResultsCount (dynamic messaging based on active filters/search)

### Stylesheets Updated (1 file)
- `app/assets/stylesheets/plants.sass`:
  - Color-aware filter buttons using CSS variables (--filter-color)
  - Search clear button styling (positioned absolute in search wrapper)
  - Collapsible group headers (clickable, with hover states, flex layout for icon/title/count)
  - Watering status filter buttons with status-specific colors (urgent=orange, today=green, scheduled=blue)
  - Group count styling

### Locales Updated (2 files)
- `config/locales/en.yml` — added filter_by_status, overdue, needs_water_today, scheduled, results_filtered, results_filtered_search
- `config/locales/es.yml` — added Spanish translations for new strings

**Additional Refinements:**
- Updated filter button styling so colored buttons show a light version (15% opacity) of their assigned color when inactive, with the full color as text. Hover increases to 25% opacity. Active state shows solid color with white text.
- Location resource cards on index page now show 12% tint of assigned color with darker left border (3px solid, 80% color + 20% black)
- Recipe info cards on index page now show 12% tint of assigned color with darker left border (3px solid, 80% color + 20% black)
- Locations index page now sorts by active plant count (descending), then alphabetically by name
- Watering status filter buttons now show light backgrounds (15% tint) when inactive, matching the location/recipe filter button pattern

**Bug Fix:**
- Fixed Recipe update error when duplicate sources were submitted - added custom `reject_ingredient` method to reject ingredients without a source_id, and `unique_recipe_sources` validation to provide user-friendly error message instead of database constraint violation

**Major UI Update: Toggleable Filters & Recipe Display Mode**

### Filter UX Overhaul
- All filters now hidden by default with "Add filter:" buttons for Status | Recipe | Location
- Clicking an "Add filter" button reveals that filter section
- Each filter section has a "✕" remove button to hide and clear active filters
- Filter sections: Status, Recipe, and Location can be independently shown/hidden

### Recipe Display Mode
- Added "Recipe" as third display mode option (alongside Watering and Location)
- Controller builds `@plants_by_recipe` grouping similar to location grouping
- Recipe groups show colored headers with collapsible content
- Recipe groups use localStorage for collapse state persistence

### View Changes
- `app/views/plants/index.html.erb`:
  - Display mode toggle now includes Recipe button (conditional on recipes existing)
  - Add filter buttons section with Status/Recipe/Location buttons
  - All filter sections wrapped with show/hide capability
  - Recipe groups rendered with colored headers similar to location groups
  - "Show more/less" toggle buttons moved inside filter containers to appear inline

### Controller Changes
- `app/controllers/plants_controller.rb`:
  - Added recipe grouping logic (elsif @display_mode == "recipe")
  - Groups plants by recipe name and color

### JavaScript Changes
- `app/javascript/controllers/location_filter_controller.js`:
  - Added targets: recipeGroup, addStatusFilterBtn, addRecipeFilterBtn, addLocationFilterBtn, locationFilterContainer, recipeFilterContainer, addFiltersContainer
  - Added show/hide methods: showStatusFilter, hideStatusFilter, showRecipeFilter, hideRecipeFilter, showLocationFilter, hideLocationFilter
  - Added updateAddFiltersVisibility() and areAllFiltersVisible() - "Add filter:" section auto-hides when all filters are visible
  - Updated filterPlants() to handle recipe display mode
  - Updated updateDisplayMode() to show/hide recipe groups
  - Hide methods clear active filters and update UI

### Styling
- `app/assets/stylesheets/plants.sass`:
  - New .add-filters container styling
  - New .add-filter-btn with dashed border and hover effects
  - New .remove-filter-btn (✕ button) styling
  - "Show more/less" toggle buttons now inline (margin removed)

### Locales
- Added translations: add_filter, status, recipe (en.yml, es.yml)

**Bug Fix:**
- Fixed filter button reordering to preserve "show less" toggle and "✕" remove buttons at the end of the list (they were being moved to the front during reordering)

**Status:** Complete — awaiting `bin/rails db:migrate`

---

## 2026-02-16 — Fix Location Display Mode Button + Client-Side Mode Switching

**Goal:** Fix the Location sort/display button on Plants Index that was not showing any results when clicked, while preserving active filter state when switching display modes.

**Problem:** Clicking the Location display mode button tried to switch modes client-side using JavaScript, but the location groups HTML was only rendered server-side when `@display_mode == "location"`. When the page loads in "watering" mode (default), those DOM elements don't exist, so the JavaScript had nothing to show.

**Root Cause:** Rails was conditionally rendering HTML structures based on the `params[:display]` parameter, so only one display mode's DOM existed at a time.

**Solution:** Changed to always render all three display modes (watering, location, recipe) in the HTML, with client-side JavaScript toggling visibility and updating the URL without page reload. This preserves filter state while maintaining proper URL reflection of current mode.

**Files Modified:**

1. `app/controllers/plants_controller.rb`:
   - Removed conditional rendering logic
   - Always build both `@plants_by_location` and `@plants_by_recipe` groupings regardless of display mode
   - This ensures all necessary data is available for client-side mode switching

2. `app/views/plants/index.html.erb`:
   - Wrapped location groups in `locationGroupsContainer` div
   - Wrapped recipe groups in `recipeGroupsContainer` div
   - Wrapped watering view in `wateringGroupsContainer` div
   - Each container has initial `display` style based on `@display_mode` (for server-side page load)
   - All three modes are always rendered

3. `app/javascript/controllers/location_filter_controller.js`:
   - Added new targets: `locationGroupsContainer`, `recipeGroupsContainer`, `wateringGroupsContainer`
   - Updated `switchDisplayMode()`:
     - Sets `displayModeValue` to new mode
     - Updates URL using `history.pushState()` without triggering navigation
     - Updates button active states
     - Calls `updateDisplayMode()` to toggle container visibility
   - Restored `updateDisplayMode()` function:
     - Shows/hides container targets based on current display mode
     - Re-applies filters and updates counts after mode switch

**Behavior:**
- Clicking Watering/Location/Recipe display buttons switches modes instantly without page reload
- URL updates to `?display=watering`, `?display=location`, or `?display=recipe` without navigation
- All active filters (location, recipe, watering status) are preserved when switching modes
- Filter state (selectedLocations, selectedRecipes, selectedWateringStatuses Sets) remains intact
- Page refreshes and direct URL access still work correctly (server renders appropriate initial state)

**Status:** Complete — ready for testing

---

## 2026-02-20 — Fix "None" Recipe Selection for Plant Edit Form

**Goal:** Allow existing plants to have their recipe changed back to "None" in the Edit form, matching the behavior of the New Plant form.

**Problem:** The New Plant form allowed selecting "None" for Recipe, but the Edit Plant form didn't provide this option for plants that already had a recipe assigned. This was because the form used `prompt: '-- None --'` which only displays when the field value is `nil`.

**Root Cause:** Rails' `collection_select` with `prompt:` option only shows the prompt text when the current value is nil. For persisted records with an existing recipe_id, the prompt didn't appear, making it impossible to clear the recipe back to nil.

**Solution:** Changed from `prompt: '-- None --'` to `include_blank: '-- None --'` on line 53 of `_form.html.erb`. The `include_blank` option keeps the "None" choice available regardless of whether a value is currently selected.

**Files Modified:**
- `app/views/plants/_form.html.erb` — changed recipe collection_select from `prompt:` to `include_blank:` (line 53)

**Status:** Complete — ready for testing

---

## 2026-02-20 — Soil Moisture Tracking Implementation

**Goal:** Add comprehensive soil moisture tracking with standalone logging, watering-integrated pre/post readings, project-wide measurement preferences (numeric vs categorical), and precise datetime-based watering records.

**Features:**
1. **Standalone moisture logging**: Record soil moisture readings at any time for any plant
2. **Watering-integrated readings**: Optional pre/post watering moisture measurements
3. **Project measurement preference**: Choose between numeric (0-100%) or categorical (Saturated/Wet/Moist/Dry/Bone Dry)
4. **Precise watering timestamps**: Upgrade from DATE to DATETIME for better tracking
5. **Timeline integration**: Display moisture readings alongside waterings in plant timeline

**Implementation Phases:**
- Phase 1: Database & Models (Non-Breaking)
- Phase 2: Standalone Moisture Logging
- Phase 3: Watering Date → DateTime Migration
- Phase 4: Watering-Moisture Integration
- Phase 5: Polish & Testing

**Status:** Implementation complete — awaiting `bin/rails db:migrate`

### Database Migrations (3 files)
- `db/migrate/20260220100000_add_moisture_measurement_type_to_projects.rb` — adds moisture_measurement_type enum (numeric/categorical) to projects table
- `db/migrate/20260220100001_create_soil_moisture_readings.rb` — creates soil_moisture_readings table with plant/watering associations, numeric/categorical values, timing enum, and notes
- `db/migrate/20260220100002_change_waterings_date_to_datetime.rb` — changes waterings.date column to datetime and renames to watered_at for precise timestamp tracking

### Models (1 new, 3 modified)
- **NEW** `app/models/soil_moisture_reading.rb` — SoilMoistureReading model with timing/value_categorical enums, validations for measurement type matching project preference, display_value helper method
- **MODIFIED** `app/models/project.rb` — added has_many :soil_moisture_readings, moisture_measurement_type enum, moisture_categories helper
- **MODIFIED** `app/models/plant.rb` — added has_many :soil_moisture_readings, latest_moisture_reading/latest_moisture_value helpers, updated waterings association and update_watering_dates to use watered_at
- **MODIFIED** `app/models/watering.rb` — added has_many :soil_moisture_readings (nullify on delete), renamed all date references to watered_at, added virtual attributes (pre_moisture, post_moisture) with after_save callback to create moisture readings

### Controllers (1 new, 3 modified)
- **NEW** `app/controllers/soil_moisture_readings_controller.rb` — standard CRUD for standalone moisture logging, forces timing: :standalone, conditional strong params based on project measurement type
- **MODIFIED** `app/controllers/waterings_controller.rb` — updated index sort to use watered_at, changed new action pre-fill from date to watered_at (Time.zone.now), added :watered_at, :pre_moisture, :post_moisture to strong params
- **MODIFIED** `app/controllers/projects_controller.rb` — added :moisture_measurement_type to strong params
- **MODIFIED** `app/controllers/plants_controller.rb` — updated timeline building to use watered_at, added standalone moisture readings to timeline

### Views (3 new, 12 modified)
- **NEW** `app/views/soil_moisture_readings/_form.html.erb` — form partial with conditional input (numeric number field or categorical select) based on project preference
- **NEW** `app/views/soil_moisture_readings/new.html.erb` — new moisture reading form
- **NEW** `app/views/soil_moisture_readings/edit.html.erb` — edit moisture reading with delete button
- **MODIFIED** `app/views/waterings/_form.html.erb` — added watering-moisture Stimulus controller, changed date field to datetime_local_field for watered_at, added toggleable pre/post moisture fields with progressive disclosure UI
- **MODIFIED** `app/views/plants/show.html.erb` — added "Log Soil Moisture" link to plant actions
- **MODIFIED** `app/views/plants/_plant.html.erb` — added latest moisture reading display to plant info card
- **MODIFIED** `app/views/plants/_timeline.html.erb` — updated watering.date to watering.watered_at, added inline display of pre/post moisture readings on watering entries, added moisture_reading timeline item type for standalone readings
- **MODIFIED** `app/views/projects/_form.html.erb` — added moisture_measurement_type dropdown (Numeric vs Categorical)
- **MODIFIED** `app/views/waterings/show.html.erb` — updated watering.date to watering.watered_at with time display
- **MODIFIED** `app/views/waterings/_watering.html.erb` — updated watering.date to watering.watered_at
- **MODIFIED** `app/views/waterings/index.html.erb` — updated watering.date to watering.watered_at
- **MODIFIED** `app/views/waterings/edit.html.erb` — updated watering.date to watering.watered_at with time display
- **MODIFIED** `app/views/plants/_waterings.html.erb` — updated watering.date to watering.watered_at
- **MODIFIED** `app/views/shared_plants/_timeline.html.erb` — updated watering.date to watering.watered_at
- **MODIFIED** `app/views/shared_plants/_watering_form.html.erb` — changed date field to datetime_local_field for watered_at

### JavaScript (1 new)
- **NEW** `app/javascript/controllers/watering_moisture_controller.js` — Stimulus controller for progressive disclosure of pre/post moisture fields in watering form (togglePre, togglePost, hidePre, hidePost actions)

### Routes
- `config/routes.rb` — added nested resources :soil_moisture_readings under plants

### Locales (2 files)
- `config/locales/en.yml` — added soil_moisture_readings translations (new, edit, create_success, update_success, delete_success), added attribute translations (watered_at, moisture_measurement_type, value_numeric, value_categorical, pre_moisture, post_moisture, measured_at)
- `config/locales/es.yml` — added Spanish translations for all new strings

### Additional Controller Updates
- **MODIFIED** `app/controllers/shared_plants_controller.rb` — updated build_timeline to use watered_at, updated shared_watering_params to permit watered_at instead of date

### Key Features Implemented
1. **Project-level moisture measurement preference** — set in project settings, applies to all plants
2. **Standalone moisture logging** — record moisture readings independently of waterings
3. **Watering-integrated moisture** — optional pre/post moisture readings on watering form with toggle buttons
4. **Precise watering timestamps** — waterings now store date AND time
5. **Timeline integration** — standalone moisture readings appear in plant timeline, watering-linked readings display inline with watering entries
6. **Latest moisture display** — plant info card shows most recent moisture reading
7. **Progressive disclosure UX** — moisture fields hidden by default, revealed with "➕ Add" buttons

### Data Migration Notes
- Waterings table: `date` column (DATE) → `watered_at` column (DATETIME)
- Existing watering records will have times set to 00:00:00 after migration
- All code references to `watering.date` have been updated to `watering.watered_at`

**Next Steps:**
1. Run `bin/rails db:migrate` to apply database changes
2. Test standalone moisture logging
3. Test watering with pre/post moisture readings
4. Test project moisture measurement type switching
5. Verify timeline displays correctly

---

### Enhancement: Auto-fill Pre-Watering Moisture from Recent Readings

**Goal:** Automatically pre-fill the pre-watering moisture field when a user has logged a standalone moisture reading within the last hour, and link to that existing reading instead of creating a duplicate.

**Implementation:**

1. **Controller Change** (`app/controllers/waterings_controller.rb`):
   - Added logic in `new` action to find most recent standalone moisture reading within 1 hour
   - Stores in `@recent_moisture_reading` instance variable

2. **View Change** (`app/views/waterings/_form.html.erb`):
   - Pre-moisture field auto-shown (not hidden) if `@recent_moisture_reading` exists
   - "Add Pre-Watering Moisture" button hidden when field is auto-shown
   - Field pre-filled with value from recent reading (numeric or categorical)
   - Added hidden field `pre_moisture_reading_id` to store reading ID
   - Added visual indicator: "✨ Auto-filled from reading X minutes ago"

3. **Model Change** (`app/models/watering.rb`):
   - Added `pre_moisture_reading_id` to virtual attributes
   - Added `link_existing_moisture_reading` method to update existing readings
   - Modified `create_moisture_readings` to check for `@pre_moisture_reading_id`
   - If ID exists: updates existing standalone reading (changes timing to `:pre_watering`, links to watering, updates timestamp)
   - If ID doesn't exist: creates new reading as before

4. **Strong Params** (`app/controllers/waterings_controller.rb`):
   - Added `:pre_moisture_reading_id` to permitted parameters

**Behavior:**
- User logs standalone moisture reading at 2:00 PM
- User navigates to water the plant at 2:30 PM
- Pre-watering moisture field appears automatically with the 2:00 PM reading value
- User can edit the value, remove it, or accept it as-is
- On submit: the existing 2:00 PM reading is updated (not duplicated) to link to the watering
- No duplicate moisture record created

**Status:** Complete

---

## 2026-02-20 — Remove Percentage Units Label from Soil Moisture Levels

**Goal:** Remove hardcoded percentage units from soil moisture measurements to support arbitrary numeric scales (not all instruments measure 0-100%).

**Problem:** The current implementation assumes percentage-based measurements and adds "%" units to numeric values. Users have different soil moisture instruments with varying scales (0-1023 for analog sensors, custom calibrated ranges, etc.), so forcing percentage interpretation is incorrect.

**Changes:**

1. **Model** (`app/models/soil_moisture_reading.rb`):
   - Removed "%" suffix from `display_value` method (line 37)
   - Removed 0-100 range constraint from validation (lines 17-19), kept numericality check

2. **Forms** (3 locations):
   - `app/views/soil_moisture_readings/_form.html.erb` — changed helper text from "Percentage (0-100%)" to "Numeric value", removed min/max constraints
   - `app/views/waterings/_form.html.erb` (2 instances) — changed helper text from "Percentage (0-100%)" to "Numeric value" (lines 97, 117), removed min/max constraints from both pre/post moisture fields

3. **Project Configuration** (`app/views/projects/_form.html.erb`):
   - Changed dropdown text from "Numeric (0-100%)" to "Numeric" (line 29)

**Impact:**
- Backward compatible - existing numeric values display correctly without "%" suffix
- Users can now use any numeric scale their instruments provide
- Categorical measurement type unaffected

**Status:** Complete — ready for testing

---

## 2026-02-20 — Fix "Content Missing" Error on New Plant Button

**Goal:** Fix the "New Plant" button at the bottom of the Plants Index page that was showing a blank "Content Missing" message instead of the expected new plant form.

**Problem:** When users clicked the "New Plant" button at the bottom of the Plants Index page (line 273), they saw "Content Missing" instead of the new plant form.

**Root Cause:** The "New Plant" link was rendered inside a `<turbo-frame id="plants-results">` frame but didn't specify `data: { turbo_frame: "_top" }`. When clicked, Turbo attempted to find a matching `<turbo-frame id="plants-results">` in the response from the `new` action, but the `new.html.erb` view doesn't provide one, resulting in "Content Missing".

**Solution:** Added `data: { turbo_frame: "_top" }` to the New Plant link to tell Turbo to break out of the frame context and navigate the full page. This matches the pattern used by other navigation links in the plants index (like in `_plant_row.html.erb`).

**Files Modified:**
- `app/views/plants/index.html.erb` (line 273) — added `data: { turbo_frame: "_top" }` to the New Plant link

**Status:** Complete — ready for testing