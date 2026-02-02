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
│       ├── .plant-card-last-watering-volume (💧)
│       ├── .plant-card-last-watering-notes (📝)
│       ├── .plant-card-last-watering-time (⌛ long/short text)
│       ├── .plant-card-location (📍)
│       └── .plant-card-container (🫙)
└── .plant-card-water-col    (clickable link, full height)
    ├── .water-icon (SVG droplet)
    └── .plant-card-water-helper (Click/Tap to Water)
```

---

# Agent Log: Plant Card Grid, Watering Splits, Pluralization & Show Page Polish

**Date:** 2026-01-29
**Task:** Responsive grid for plant card details, split watering info, fix pluralization, and Show page color theming

## Summary

Multiple improvements to the plant card on both Index and Show pages: responsive CSS grid for meta attributes, split last watering info into separate volume/notes fields, fixed "1 days late" pluralization bug, added urgency-based color theming to the Show page, and various responsive breakpoint refinements.

## Changes Made

### Models

- **`app/models/plant.rb`**
  - Fixed `time_until_watering_text` and `time_until_watering_short_text` to use `late_days == 1 ? 'day' : 'days'` instead of unconditional "days"

### Helpers

- **`app/helpers/plants_helper.rb`**
  - Removed `last_watering_info_text` method
  - Added `last_watering_volume_text(plant)` — returns volume string or nil
  - Added `last_watering_notes_text(plant)` — returns notes string or nil
  - Changed "Last watered" to "Watered" in `last_watering_time_text`

### Views

- **`app/views/plants/_plant_row.html.erb`** (Index card)
  - Replaced single `.plant-card-last-watering-info` with separate `.plant-card-last-watering-volume` (💧) and `.plant-card-last-watering-notes` (📝)
  - Reordered meta slots: volume, notes, last watered time, location, container
  - Changed watering suggestion emoji from 💧 to 🕐

- **`app/views/plants/_plant.html.erb`** (Show page)
  - Updated helper text from "Click"/"Tap" to "Click to Water"/"Tap to Water"

### Stylesheets

- **`app/assets/stylesheets/plants.sass`** (Index page)
  - `.plant-card-meta` now uses CSS grid: `grid-template-columns: minmax(0, 275px) minmax(0, 1fr)`
  - Font size `1.05em` on desktop grid
  - `.plant-card-watering` font size `1.1em`, never reduced at any breakpoint
  - Replaced `.plant-card-last-watering-info` styles with `.plant-card-last-watering-volume` and `.plant-card-last-watering-notes`
  - Water icon link: added subtle default backgrounds per urgency (blue `0.05`, green `0.05`, yellow `0.07` opacity)
  - **768px breakpoint**: only grid → 1 column and meta font size → `0.85em`
  - **480px breakpoint** (new): long/short text switch, desktop/mobile visibility, graphic column shrink, water col padding reduction, `.plant-card-name` word wrap, `section#primary` side padding → 0

- **`app/assets/stylesheets/shared.sass`** (Show page)
  - `.watering-section` urgency-based backgrounds: blue (normal), green (today), yellow (urgent) with matching `border-left-color`
  - `.water-icon-link` urgency-based subtle default backgrounds with hover states

## Responsive Breakpoints

| Breakpoint | Changes |
|------------|---------|
| Desktop (>768px) | 2-column grid (275px max + 1fr), font 1.05em, long text, full padding |
| ≤768px | 1-column grid, font 0.85em, long text still shown, padding unchanged |
| ≤480px | Short text replaces long text, desktop/mobile visibility swap, plant name wraps, section margins → 0 |

## Urgency Color Scheme (Index + Show)

| Urgency | Card Background | Water Button Default | Water Button Hover |
|---------|----------------|---------------------|--------------------|
| normal | $lightblue | rgba(14,72,123, 0.05) | rgba(14,72,123, 0.15) |
| today | $lightgreen | rgba(0,77,64, 0.05) | $lightgreen |
| urgent | $lightyellow | rgba(206,154,0, 0.07) | $lightyellow |

---

# Agent Log: Share Link Improvements

**Date:** 2026-01-31
**Task:** Friendly shared link errors + reusable/regeneratable tokens

## Summary

Added `share_enabled` boolean to plants so revoking a share link disables access without deleting the token. This allows "Create Share Link" to re-enable the same URL after revoking, and a new "Regenerate Link" button to generate a fresh token (invalidating the old one). Invalid or disabled share links now show a friendly error page instead of a 500.

## Changes Made

### Database

- **New migration:** `db/migrate/20260131160000_add_share_enabled_to_plants.rb`
  - Adds `share_enabled` boolean column (default `false`)
  - Backfills existing shared plants: `Plant.where.not(share_token: nil).update_all(share_enabled: true)`

### Models

- **`app/models/plant.rb`**
  - `shared?` now checks both `share_token.present?` and `share_enabled?`
  - `generate_share_token!` only generates a new token if nil, always sets `share_enabled: true`
  - `revoke_share_token!` sets `share_enabled: false` instead of deleting the token
  - New `regenerate_share_token!` generates a fresh token and sets `share_enabled: true`

### Controllers

- **`app/controllers/plants_controller.rb`**
  - Added `regenerate_share` to `before_action :set_plant` list
  - New `regenerate_share` action calls `regenerate_share_token!` and redirects with flash

- **`app/controllers/shared_plants_controller.rb`**
  - `set_plant` uses `find_by` instead of `find_by!`
  - Renders `not_found` view with shared layout and 404 status if plant is nil or `share_enabled?` is false

### Routes

- **`config/routes.rb`**
  - Added `post 'regenerate_share'` to plants member block

### Views

- **`app/views/shared_plants/not_found.html.erb`** (new)
  - Friendly error page: "This link doesn't seem to work. If you think this is an error, contact the owner."

- **`app/views/plants/show.html.erb`**
  - Added "Regenerate Link" button with confirmation warning when plant is shared

### Locales

- **`config/locales/en.yml`** + **`config/locales/es.yml`**
  - `plants.show.regenerate_share` / `plants.show.regenerate_confirm`
  - `plants.messages.share_regenerated`
  - `shared_plants.not_found_message` / `shared_plants.not_found_contact`

## Behavior Changes

| Scenario | Before | After |
|----------|--------|-------|
| Revoke share link | Token deleted, URL permanently broken | Token kept, `share_enabled` set to false, URL returns friendly 404 |
| Create share link after revoking | New token generated, new URL | Same token re-enabled, same URL works again |
| Regenerate link | N/A | New token generated, old URL shows friendly 404 |
| Invalid/disabled token visited | 500 error (RecordNotFound) | Friendly "link doesn't work" page (404) |

## Required Action

Run database migration:
```bash
bin/rails db:migrate
```

---

# Agent Log: Account Deletion + Settings Restyle

**Date:** 2026-01-31
**Task:** Add account deletion with async data cleanup, restyle settings page, add `login_enabled` admin control

## Summary

Added account deletion functionality with a restyled card-based settings page. Deletion is async — the user's `login_enabled` flag is set to `false` immediately, then a background job destroys all their data. Admins can toggle `login_enabled` per user from `/users`. The settings page now uses a card layout consistent with the plant info cards.

## Changes Made

### Database

- **`db/migrate/..._change_log_entries_user_id_nullify_on_delete.rb`**
  - Allows null `user_id` on `log_entries`
  - Replaces FK with `ON DELETE NULLIFY` so log entries survive user deletion

- **`db/migrate/..._add_login_enabled_to_users.rb`**
  - Adds `login_enabled` boolean column (default: `true`, not null)

### Models

- **`app/models/user.rb`**
  - Added `dependent: :destroy` to `has_many :projects` and `has_many :collaborations`

- **`app/models/project.rb`**
  - Added `dependent: :destroy` to all child associations (plants, zones, locations, sensors, etc.)
  - Reordered associations so `plants` is destroyed before `locations` (FK dependency)

- **`app/models/log_entry.rb`**
  - Changed `belongs_to :user` to `optional: true`

### Jobs

- **`app/jobs/delete_user_data_job.rb`** (new)
  - Finds user by ID and calls `destroy`
  - Handles `ActiveRecord::RecordNotFound` gracefully

### Controllers

- **`app/controllers/settings_controller.rb`**
  - Added `before_action :authenticate`
  - `destroy` action: verifies password, sets `login_enabled: false`, enqueues `DeleteUserDataJob`, clears session, redirects with scheduled-deletion message

- **`app/controllers/sessions_controller.rb`**
  - Rejects login when `login_enabled` is `false` with "account disabled" message

- **`app/controllers/users_controller.rb`**
  - Added `update` action for admins to toggle `login_enabled`

### Routes

- **`config/routes.rb`**
  - Added `delete 'settings', to: 'settings#destroy'`

### Views

- **`app/views/settings/index.html.erb`** — Restyled with three cards:
  - Account Information card (email, created, updated)
  - Security card (update password, log out)
  - "Delete Account" button that reveals the Danger Zone card with password form and confirmation dialog

- **`app/views/users/index.html.erb`**
  - Added "Login Enabled" column with toggle button per user

### Stylesheets

- **`app/assets/stylesheets/shared.sass`**
  - Added `.settings-card` styles (green-themed, border-left accent)
  - `.settings-card.danger` variant (red-themed)
  - Settings page widened to 600px (auth pages remain at 450px)

### Translations

- **`config/locales/en.yml`** + **`config/locales/es.yml`**
  - `account.delete_account`, `account.confirm_delete_account`, `account.delete_account_success` (scheduled deletion message), `account.password_required`, `account.incorrect_password`, `account.security`, `account.danger_zone`, `account.account_information`
  - `errors.account_disabled`
  - `attributes.login_enabled`

### Scripts

- **`util/clone_production_db_to_local.sh`**
  - Added `rails db:migrate` after pg_restore

## Deletion Flow

1. User clicks "Delete Account" button — reveals danger zone card
2. User enters password and confirms — controller verifies password
3. `login_enabled` set to `false` immediately
4. `DeleteUserDataJob` enqueued for async destruction
5. Session cleared, redirected to login with "scheduled for deletion" notice
6. If user tries to log back in before job runs — "account disabled" error

## Behavior Changes

| Scenario | Before | After |
|----------|--------|-------|
| Settings page | Plain text list | Card-based layout with sections |
| Delete account | N/A | Password-confirmed async deletion |
| Re-login after deletion | N/A | Blocked by `login_enabled: false` |
| Admin user management | View-only user list | Can toggle `login_enabled` per user |

## Required Action

Run database migrations:
```bash
bin/rails db:migrate
```

---

# Agent Log: Cards Layout for Tanks, Locations, Zones, Sensors, and Sensor Types

**Date:** 2026-02-01
**Task:** Introduce card-based layouts for resource index/show/edit/new pages

## Summary

Converted Tanks, Locations, Zones, Sensors, Sensor Types, and Water Tests views from plain text/table layouts to a consistent card-based design system matching the Plants pages. Renamed plant-specific CSS classes to generic names for reuse across all resources.

## Changes Made

### Stylesheets

- **`app/assets/stylesheets/shared.sass`**
  - Renamed `.plant-info-card` → `.info-card`, `.plant-info-grid` → `.info-card-grid`, `.plant-info-section` → `.info-card-section`
  - Added `.resource-cards` (flex column container) and `.resource-card` (clickable card with hover state) for index pages
  - Added form centering for `main.tanks`, `main.locations`, `main.zones`, `main.sensors`, `main.sensor_types`, `main.water_tests` on new/edit/create/update actions
  - Extended label/field styling selector to include all new resource controllers

### Views — Plants

- **`app/views/plants/_plant.html.erb`** — Updated class names to `.info-card`, `.info-card-grid`, `.info-card-section`

### Views — Tanks

- **`app/views/tanks/_tank.html.erb`** — Rewritten as compact `.resource-card` (name + capacity + location)
- **`app/views/tanks/index.html.erb`** — Uses `.resource-cards` container, removed "Show this Tank" links
- **`app/views/tanks/show.html.erb`** — Uses `.info-card` with `.info-row` label/value pairs
- **`app/views/tanks/edit.html.erb`** — Wrapped in `.settings-card` with breadcrumbs
- **`app/views/tanks/new.html.erb`** — Wrapped in `.settings-card` with breadcrumbs

### Views — Locations

- **`app/views/locations/_location.html.erb`** — Compact `.resource-card` (name + zone + plant count)
- **`app/views/locations/index.html.erb`** — Uses `.resource-cards` container
- **`app/views/locations/show.html.erb`** — Uses `.info-card` layout
- **`app/views/locations/edit.html.erb`** — Wrapped in `.settings-card`
- **`app/views/locations/new.html.erb`** — Wrapped in `.settings-card`

### Views — Zones

- **`app/views/zones/_zone.html.erb`** — Compact `.resource-card` (name + temp/humidity + sensor count)
- **`app/views/zones/index.html.erb`** — Uses `.resource-cards` container
- **`app/views/zones/show.html.erb`** — Uses `.info-card` with inline sensor list as `.resource-cards`
- **`app/views/zones/edit.html.erb`** — Wrapped in `.settings-card`
- **`app/views/zones/new.html.erb`** — Wrapped in `.settings-card`

### Views — Sensors

- **`app/views/sensors/_sensor.html.erb`** — Compact `.resource-card` (name + zone + readings)
- **`app/views/sensors/_sensors.html.erb`** — Uses `.resource-cards` wrapper
- **`app/views/sensors/show.html.erb`** — Uses `.info-card` with all sensor details
- **`app/views/sensors/edit.html.erb`** — Wrapped in `.settings-card`
- **`app/views/sensors/new.html.erb`** — Wrapped in `.settings-card`

### Views — Sensor Types

- **`app/views/sensor_types/_sensor_type.html.erb`** — Compact `.resource-card` (name + temp/humidity ranges)
- **`app/views/sensor_types/index.html.erb`** — Uses `.resource-cards` container
- **`app/views/sensor_types/show.html.erb`** — Uses `.info-card` with all specs
- **`app/views/sensor_types/edit.html.erb`** — Wrapped in `.settings-card`
- **`app/views/sensor_types/new.html.erb`** — Wrapped in `.settings-card`

### Views — Water Tests

- **`app/views/water_tests/new.html.erb`** — Wrapped in `.settings-card`
- **`app/views/water_tests/edit.html.erb`** — Wrapped in `.settings-card`
- **`app/views/water_tests/_form.html.erb`** — Removed all Tailwind classes, uses app styles (`.field`, `.submit`, `.auth-errors`, `.saveButton`)
- **`app/views/water_tests/_water_tests.html.erb`** — Removed empty `class=""` attributes
- **`app/views/water_tests/index.html.erb`** — Removed Tailwind classes, simplified layout

## Design System

| Component | Usage | CSS Class |
|-----------|-------|-----------|
| Resource card | Index page list items (clickable) | `.resource-card` inside `.resource-cards` |
| Info card | Show page detail display | `.info-card` > `.info-card-grid` > `.info-card-section` with `.info-row` |
| Settings card | Edit/New form wrapper | `.settings-card` |

## Behavior Changes

| Scenario | Before | After |
|----------|--------|-------|
| Index pages | Plain text with separate "Show" links | Clickable cards linking to show page |
| Show pages | Rendered index partial with raw HTML | Structured info-card with label/value rows |
| Edit/New pages | Unstyled forms | Centered `.settings-card` matching Plants pattern |
| Water test form | Tailwind utility classes | App's native form styles |
