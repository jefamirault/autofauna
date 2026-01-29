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

---

# Agent Log: Mobile UX Improvements

**Date:** 2026-01-26
**Task:** Improve mobile experience for Plants Index and navigation

## Summary

Implemented three mobile UX improvements:
1. Responsive card layout for Plants Index on mobile screens
2. Auto-close navigation menu when selecting an item on mobile
3. Fix FOUC (flash of unstyled content) when navigating between pages

## Changes Made

### 1. Mobile Plants Index Card Layout

**File:** `app/assets/stylesheets/plants.sass`

Added responsive styles for screens ≤600px that transform the table into stacked cards:

| Row | Content |
|-----|---------|
| 1 | Graphic (48px) + Plant Name + Action Button |
| 2 | Watering suggestion with "Water:" prefix |
| 3 | Last watering with "Last:" prefix |
| 4 | Location (📍) + Container (🪴) side-by-side |

Features:
- Flexbox with `order` property for column reordering
- Blue left border accent for card styling
- Touch-friendly action buttons with active states
- Automatic support for archive page (fewer columns)

### 2. Mobile Nav Auto-Close

**Files:**
- `app/javascript/controllers/sidebar_controller.js` - Added `closeOnMobile()` method
- `app/views/layouts/application.html.erb` - Added Stimulus action to nav elements

Behavior:
- When user taps a nav link on mobile (<600px), sidebar closes automatically
- Desktop behavior unchanged
- State persisted to localStorage

### 3. Sidebar FOUC Fix

**Problem:** After closing sidebar and navigating, sidebar would flash open then animate closed again.

**Root Cause:** Sidebar state was only applied after Stimulus controller connected, and global `transition: all 0.15s` caused visible animation.

**Solution:** Apply sidebar state before render using inline script.

**Files Modified:**

| File | Change |
|------|--------|
| `app/views/layouts/application.html.erb` | Added inline `<script>` in `<head>` to apply `sidebarMinimized` and `no-transition` classes before render |
| `app/assets/stylesheets/layout.sass` | Added `html.sidebarMinimized body` selectors for early class support |
| `app/assets/stylesheets/shared.sass` | Added `html.no-transition *` rule to disable transitions during load |
| `app/javascript/controllers/sidebar_controller.js` | Remove `no-transition` after connect; manage class on both `html` and `body` |

## Behavior Changes

| Scenario | Before | After |
|----------|--------|-------|
| Plants Index on mobile | Table with horizontal scroll, columns cut off | Stacked card layout, all info visible |
| Tap nav link on mobile | Sidebar stays open, user must close manually | Sidebar auto-closes |
| Navigate between pages (mobile) | Sidebar flashes open then animates closed | Sidebar stays closed instantly |

---

# Agent Log: Plants Index Card Layout Refactor

**Date:** 2026-01-26
**Task:** Refactor Plants index to flexbox card layout with urgency-based color coding

## Summary

Refactored the Plants index from table-based layout to a clean flexbox card layout. Added watering urgency-based color coding for rows and water buttons. The layout is now a 3-column structure: plant graphic, details, and full-height water button.

## Changes Made

### Views

- **`app/views/plants/_plant_row.html.erb`** - Complete rewrite
  - Changed from `<tr>/<td>` table structure to `<div>` flexbox structure
  - 3-column layout: graphic, details, water button
  - Added `watering_urgency` class to card for CSS color targeting
  - Water button now uses SVG droplet icon instead of text
  - Uses placeholder.png when plant has no graphic selected

- **`app/views/plants/index.html.erb`**
  - Changed from `<table class="blue plant-cards">` to `<div class="plant-cards">`
  - Removed table header render

- **`app/views/plants/archive.html.erb`**
  - Same changes as index (div container instead of table)

- **`app/views/plants/edit.html.erb`**
  - Changed delete button class from `buttonLink` to `buttonLinkDanger`

### Stylesheets

- **`app/assets/stylesheets/plants.sass`** - Complete rewrite of card styles
  - Color variables for urgency states (green, blue, yellow + light variants)
  - `.plant-cards` - flex column container with gap
  - `.plant-card` - flex row with urgency-based background colors
  - `.plant-card-graphic` - column 1, no margins, 100x100 image
  - `.plant-card-details` - column 2, with padding, contains name/watering/meta
  - `.water-icon-link` - column 3, full height, urgency-colored icon
  - Overflow handling for long watering notes (text-overflow: ellipsis)

- **`app/assets/stylesheets/shared.sass`**
  - Added `.buttonLinkDanger` class for red delete buttons

## Card Structure

```
.plant-card (display: flex)
├── .plant-card-graphic     (column 1: 100x100 image, no margins)
├── .plant-card-details     (column 2: padding, flex: 1)
│   ├── .plant-card-name
│   ├── .plant-card-watering
│   └── .plant-card-meta
│       ├── .plant-card-last-watering
│       ├── .plant-card-location
│       └── .plant-card-container
└── .water-icon-link        (column 3: full height, SVG icon)
```

## Urgency Color Coding

| Status | Background | Border/Icon Color | Text Color |
|--------|------------|-------------------|------------|
| normal | $lightblue | $blue | $blue |
| today | $lightgreen | $green | $green |
| urgent | $lightyellow | $yellow | $yellow |
| none | light grey | #999 | #999 |

## Features

| Feature | Description |
|---------|-------------|
| Full-height water button | Entire right side of card is clickable |
| Urgency colors | Row background and icon color reflect watering status |
| Placeholder graphic | Plants without graphic show placeholder.png |
| Ellipsis overflow | Long watering notes truncate with ellipsis |
| Red delete button | Delete button on edit page uses danger styling |

---

# Agent Log: Plant Card UI Enhancements

**Date:** 2026-01-28
**Task:** Improve plant card layout, responsive text, and edit form safety

## Summary

Redesigned the plant card layout from 3 columns to a structured layout with UID, name above graphic, responsive long/short text for watering info, selective bold formatting, and a safer archived checkbox on the edit form.

## Changes Made

### Views

- **`app/views/plants/_plant_row.html.erb`** - Restructured card layout
  - Plant label (UID + name) displayed above graphic in a fixed-width column
  - Watering suggestion moved to first item in details column
  - Last watering split into separate time and info lines (with 🧪 icon for info)
  - Jar icon (🫙) replaces plant pot icon for container
  - Entire water column is now a single clickable link (not just the icon)
  - "Click to Water" / "Tap to Water" helper text beneath water button
  - Long/short text spans with `.long-text` / `.short-text` classes for responsive display
  - `.html_safe` used for watering text containing `<strong>` tags

- **`app/views/plants/_form.html.erb`** - Safer archived checkbox
  - Checkbox and label displayed inline in `.archived-checkbox` wrapper
  - Added `data-confirm` dialog to prevent accidental archiving

### Models

- **`app/models/plant.rb`**
  - `time_until_watering_text` — added `<strong>` tags around key parts (e.g. "Watering **5 days late**", "Water **today**", "Water in **3 days**")
  - `time_until_watering_short_text` — new method for mobile-friendly abbreviated text with `<strong>` tags

### Helpers

- **`app/helpers/plants_helper.rb`**
  - `last_watering_time_text` — now returns "Last watered **X days ago**" with `<strong>` tag
  - `last_watering_time_short_text` — new method returning abbreviated "**X days**" with `<strong>` tag
  - `last_watering_info_text` — new method returning volume/notes or nil

### Stylesheets

- **`app/assets/stylesheets/plants.sass`**
  - Fixed-width graphic column (160px desktop, 120px mobile) with `max-width` constraint
  - Plant name truncates with ellipsis for long names
  - Graphic image has `min-width: 120px` to prevent shrinking
  - `.plant-card-water-col` styled as the clickable link container with hover states
  - `.plant-card-watering` no longer has blanket `font-weight: 500` (bold is selective via `<strong>`)
  - `.long-text` / `.short-text` / `.desktop-only` / `.mobile-only` responsive visibility classes
  - `.archived-checkbox` — inline flex layout with normal-scale checkbox
  - Mobile breakpoint (768px) swaps long/short text and adjusts sizing

## Card Structure

```
.plant-card (display: flex)
├── .plant-card-graphic-col  (fixed width: 160px / 120px mobile)
│   ├── .plant-card-name     (plant.label: "#uid name", truncates)
│   └── .plant-card-graphic  (120px image, min-width enforced)
├── .plant-card-details      (flex: 1)
│   ├── .plant-card-watering (💧 suggestion, long/short text)
│   └── .plant-card-meta
│       ├── .plant-card-last-watering-time (⌛ long/short text)
│       ├── .plant-card-last-watering-info (🧪 volume/notes)
│       ├── .plant-card-location (📍)
│       └── .plant-card-container (🫙)
└── .plant-card-water-col    (clickable link, full height)
    ├── .water-icon (SVG droplet)
    └── .plant-card-water-helper (Click/Tap to Water)
```
