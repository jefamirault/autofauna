# Agent Log: Conceal Multi-Project Feature

**Date:** 2026-01-26
**Task:** Hide multi-project functionality from regular users

## Summary

Implemented changes to conceal the multi-project feature from regular users. New users now automatically get a single project created and are directed straight to their plants. The project structure is invisible to them. An `advanced_mode` flag on users supports future opt-in to reveal full project functionality.

## Changes Made

### Database

- **New migration:** `db/migrate/20260126204657_add_advanced_mode_to_users.rb`
  - Adds `advanced_mode` boolean column to users table
  - Defaults to `false`

### Models

- **`app/models/user.rb`**
  - Added `after_create :create_default_project` callback
  - New users automatically get a project named "My Plants"

### Controllers

- **`app/controllers/registrations_controller.rb`**
  - Modified `create` action to set current project after registration
  - Redirects to `plants_path` instead of `root_path`

- **`app/controllers/sessions_controller.rb`**
  - Added `auto_select_project_for(user)` private method
  - Non-advanced users with one project are auto-selected into it on login

- **`app/controllers/application_controller.rb`**
  - Added `show_project_ui?` helper method (returns true only for advanced_mode users)
  - Modified `login` method to create default project for existing users who have none

- **`app/controllers/projects_controller.rb`**
  - Modified `index` action to redirect non-advanced users to plants
  - Added `before_action :require_advanced_mode` for show, edit, new actions
  - Added `require_advanced_mode` private method

### Views

- **`app/views/layouts/application.html.erb`**
  - Wrapped current project display with `show_project_ui?` conditional
  - Wrapped "Project Settings" nav link with `show_project_ui?` conditional

## Behavior Changes

| Scenario | Before | After |
|----------|--------|-------|
| New user registers | Lands on projects page to create/select project | Auto-creates "My Plants" project, lands on plants index |
| User logs in | May need to select project | Auto-selects single project for non-advanced users |
| Visit `/projects` | Shows project list | Redirects non-advanced users to plants |
| Visit `/projects/:id` | Shows project settings | Redirects non-advanced users to plants |
| Sidebar | Shows current project name and settings link | Hidden for non-advanced users |

## Required Action

Run database migration:
```bash
bin/rails db:migrate
```

## Future Work

- Add settings UI for users to enable `advanced_mode`
- Once enabled, users can create multiple projects and access sharing features
- Admin users and `advanced_mode` users retain full project functionality

---

# Agent Log: Plant Graphics Feature

**Date:** 2026-01-26
**Task:** Add profile picture/graphic selection for plants

## Summary

Implemented a plant graphics feature that allows users to select a profile picture for each plant from a library of PNG images. The feature includes a dropdown selector with live preview, auto-matching based on plant name, and display on both the show page and index table.

## Changes Made

### Database

- **Migration:** Added `graphic` string column to plants table (already existed in schema)

### Models

- **`app/models/concerns/plant_graphics.rb`** (new file)
  - Dynamically reads available graphics from `app/assets/images/plant_graphics/` folder
  - `available_graphics` - returns list of graphic names from PNG files
  - `graphics_for_select` - returns options for dropdown
  - `match_graphic_for_name(name)` - matches plant name to graphic (e.g., "My Monstera" matches "monstera")
  - `graphic_path` - returns asset path for the plant's graphic
  - Validates graphic is in available list

- **`app/models/plant.rb`**
  - Includes `PlantGraphics` concern
  - Added `graphic` to `ransackable_attributes`

### Controllers

- **`app/controllers/plants_controller.rb`**
  - Added `graphic` to permitted parameters
  - Added `suggest_graphic` action - returns JSON with matched graphic for auto-complete

### Routes

- **`config/routes.rb`**
  - Added `get :suggest_graphic` as collection route on plants

### JavaScript

- **`app/javascript/controllers/plant_graphic_controller.js`** (new file)
  - Stimulus controller for graphic selection
  - `nameChanged()` - debounced (300ms) auto-suggestion when typing plant name
  - `graphicChanged()` - updates preview, marks manual selection
  - `updatePreview()` - shows selected graphic image
  - Manual selection prevents auto-matching from overriding

### Views

- **`app/views/plants/_form.html.erb`**
  - Added Stimulus controller data attributes with graphic paths JSON
  - Added graphic dropdown selector before submit button
  - Added preview image that updates on selection
  - Connected name field to trigger auto-matching

- **`app/views/plants/show.html.erb`**
  - Replaced breadcrumb navigation with plant graphic in header
  - Graphic links back to plants index

- **`app/views/plants/_plant.html.erb`**
  - Removed graphic display (moved to header)

- **`app/views/plants/_plant_row.html.erb`**
  - Added graphic column as first column
  - Shows 64x64 graphic image linking to plant

- **`app/views/plants/_plant_row_header.html.erb`**
  - Added empty graphic column header

### Stylesheets

- **`app/assets/stylesheets/plants.sass`**
  - `.graphicColumn` - column styling for index table
  - `.plant-row-graphic` - 64x64 image in table rows
  - `.plant-graphic-selector` - form selector container
  - `.graphic-select-container` - flexbox layout for dropdown + preview
  - `.plant-graphic-preview-image` - 64x64 preview in form
  - `.plant-header` - flexbox header with graphic
  - `.plant-header-graphic` - 128x128 graphic in show page header

### Translations

- **`config/locales/en.yml`**
  - Added `attributes.graphic: "Plant Graphic"`
  - Added `plants.form.select_graphic: "Select a graphic..."`

- **`config/locales/es.yml`**
  - Added `attributes.graphic: "Imagen de Planta"`
  - Added `plants.form.select_graphic: "Seleccionar imagen..."`

### Assets

- **`app/assets/images/plant_graphics/`** (new directory)
  - User-provided PNG files (19 images): aloe, arrowhead_plant, basil, cactus, cannabis, christmas_cactus, fern, flamingo_flower, geranium, hibiscus, marigold, monstera, orchid, pothos, rosemary, snake_plant, spider_plant, thyme, tomato

## Features

| Feature | Description |
|---------|-------------|
| Dropdown selector | Select from available graphics in plant form |
| Live preview | Selected graphic displays immediately next to dropdown |
| Auto-matching | Typing "monstera" in name field auto-selects monstera graphic |
| Manual override | Once user manually selects, auto-matching stops |
| Show page header | Graphic replaces breadcrumb, links to plants index |
| Index table | Graphic shown as first column in plant list |
| Dynamic loading | Graphics list read from folder, no hardcoding |

## Adding New Graphics

1. Add PNG file to `app/assets/images/plant_graphics/`
2. Filename becomes the graphic name (e.g., `rose.png` → "Rose" in dropdown)
3. No code changes required - automatically detected
