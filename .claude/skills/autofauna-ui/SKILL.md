---
name: autofauna-ui
description: UI/UX design patterns and conventions for the Autofauna Rails app. Use when creating or modifying views, forms, show pages, layouts, headers, or Stimulus controllers. Provides the design system rules, CSS class inventory, header configuration, and layout architecture needed to build consistent pages.
---

# Autofauna UI/UX Skill

## Page Types and Their Card Styles

Every page falls into one of these patterns:

| Page Type | Wrapper Class | Background | Use For |
|-----------|--------------|------------|---------|
| Edit/New forms | `.settings-card` | `#f7f7f7` opaque, green left border | All create/edit forms |
| Show pages (over background) | `.settings-card` | Same as above | Show pages where `section#primary` is transparent |
| Show pages (normal) | `.info-card` > `.info-card-grid` > `.info-card-section` | `$lightgreen` semi-transparent | Show pages with opaque main background (e.g., plant show) |
| Danger actions | `.settings-card.danger` | Red/brown left border | Delete buttons, destructive actions |

**Key rule:** When `section#primary` has `background: transparent` (centered form pages), always use `.settings-card` — never `.info-card`, because `.info-card-section` has a translucent background that's unreadable against the site background image.

## Centered Form Page Pattern

Edit/new/show pages for most resources use a centered, transparent-background layout. The CSS selector pattern is:

```sass
main
  &.controllerName
    &.new, &.edit, &.create, &.update
      section#primary
        background: transparent
        display: flex
        flex-direction: column
        align-items: center
        justify-content: center
        .settings-card
          width: 100%
          max-width: 450px
          @media (max-width: 600px)
            width: calc(100% - 2rem)
            margin: 0 1rem
```

This is defined in `shared.sass`. When adding a new controller to this pattern, add it to the appropriate selector list. The body `<main>` element gets `class="<controller> <action>"` from the layout.

**Currently using this pattern:**
- Plants: edit/new/create/update (in its own `&.plants` block)
- Waterings: new/edit/create/update/show/water/quick_water (in its own `&.waterings` block)
- Tanks, locations, zones, sensors, sensor_types, water_tests, recipes, recipe_sources, recipe_batches: new/edit/create/update (shared block)

## Form Field Layout

### Single fields
Wrap in `<div class="field">` for consistent spacing:
```erb
<div class="field">
  <%= form.label :name, "Label" %>
  <%= form.text_field :name %>
</div>
```

### Paired fields on one line
Use `.field-row` with `.field-row-item` children:
```erb
<div class="field-row">
  <div class="field-row-item">
    <%= form.label :volume %>
    <%= form.number_field :volume %>
  </div>
  <div class="field-row-item">
    <%= form.label :units %>
    <%= form.select :units, ... %>
  </div>
</div>
```

CSS (in `shared.sass` under the form-styling selector):
```sass
.field-row
  display: flex
  gap: 1rem
  align-items: flex-end
  .field-row-item
    flex: 1
```

### Range inputs
Use `.rangeInputContainer` for min-max style ranges (e.g., watering frequency).

### Submit buttons
Wrap in `<div class="submit">` for top margin spacing.

## Info Rows (Show Pages)

`.info-row` provides a flex row with label on left, value on right, separated by bottom borders:
```erb
<div class="info-row">
  <strong>Label</strong>
  <span class="value">Content</span>
</div>
```

Works inside both `.settings-card` and `.info-card-section`.

## Header Configuration

The header is context-aware, configured via `header_config` in `ApplicationHelper`. Each controller returns a hash:

```ruby
{ icon: 'icon.png',           # Section icon for sidebar logo
  title: title,               # Displayed in #headerTitle (centered)
  section_title: section_title, # Shown in hamburger button
  gradient_class: 'header-x', # CSS class for gradient colors
  nav_path: index_path,       # Where sidebar logo links to
  plant_graphic: nil }         # Legacy: renders in section#primary (prefer header graphic instead)
```

**Title convention:** On index pages, show the section name. On show/edit pages, show the specific resource name (e.g., the plant name, recipe name).

### Plant Graphic in Header (Expanded Header) — Preferred Pattern

Both plant and watering show/edit pages render the plant graphic inside the header itself, creating a taller two-row header. This is the preferred approach over the legacy `plant_graphic` content-area banner.

**View pattern** — add to any view that has access to a plant with a graphic:
```erb
<% if @plant&.graphic_path %>
  <% content_for :header_extra do %>
    <div class="header-plant-graphic">
      <%= image_tag @plant.graphic_path, class: 'plant-graphic-image' %>
    </div>
  <% end %>
<% end %>
```

Always set `plant_graphic: nil` in `header_config` to prevent double-rendering in `section#primary`.

**CSS** — the expanded header is defined in `layout.sass` with a shared selector for all controllers that use it:

```sass
// Currently: plants and waterings
body:has(main.waterings):has(.header-plant-graphic), body:has(main.plants):has(.header-plant-graphic)
  --header-height: 14.5rem
  header
    grid-template-rows: 4.5rem 1fr
  button.hamburgerToggle
    height: 4.5rem
    .hamburger-title
      line-height: 4.5rem
  #headerTitle, #headerRight
    align-self: center
```

**To add a new controller to this pattern:** append `, body:has(main.newController):has(.header-plant-graphic)` to the selector.

### Scroll-Based Header Collapse

The `dynamic_header_controller` (attached to `<main>` via the layout) watches scroll position and toggles `body.header-collapsed` when the user scrolls past a threshold (default 30px). This collapses the expanded header back to default height with smooth CSS transitions:

```sass
// Collapsed state (in the plant-graphic body selector)
&.header-collapsed
  --header-height: 4.5rem
  grid-template-rows: 4.5rem 1fr
  header
    grid-template-rows: 4.5rem 0fr    // second row collapses to 0
  #headerTitle
    opacity: 1                         // title fades in
  .header-plant-graphic
    opacity: 0                         // graphic fades out
    pointer-events: none
```

The expanded header uses `transition: grid-template-rows 0.3s ease` and `overflow: hidden` on the header for smooth animation. When scrolled back to top, the class is removed and the header re-expands.

**Important mobile overrides needed:** The hamburger button and gradient blending use `var(--header-height)` for sizing. Override these to the original base size (4rem mobile) to prevent the hamburger from stretching:

```sass
  @media (max-width: 600px)
    --header-height: 11rem
    header
      grid-template-rows: 4rem 1fr
      padding-left: 4rem
      background: linear-gradient(to right, var(--section-color-start) 4rem, transparent calc(4rem + 3rem)), var(--section-gradient) !important
    button.hamburgerToggle
      width: 4rem
      height: 4rem
      .hamburger-title
        line-height: 4rem
```

**`.header-plant-graphic` styles** (also in `layout.sass`):
```sass
.header-plant-graphic
  grid-row: 2
  grid-column: 1
  display: flex
  justify-content: center
  align-items: center
  padding-bottom: 0.5rem
  .plant-graphic-image
    max-height: 9rem          // desktop
    object-fit: contain
    filter: drop-shadow(0 2px 6px rgba(0,0,0,0.2))
  @media (max-width: 600px)
    .plant-graphic-image
      max-height: 6rem        // mobile
```

### Legacy: Plant Graphic in Content Area (Banner)

The layout still supports rendering a plant graphic in `section#primary` via the `plant_graphic` key in `header_config`. This is no longer used by plants or waterings (both set `plant_graphic: nil`) but the mechanism remains:

```erb
<%# In layouts/application.html.erb %>
<% if config[:plant_graphic] %>
  <div class="plant-graphic-banner">
    <%= image_tag config[:plant_graphic], class: 'plant-graphic-image' %>
  </div>
<% end %>
```

## No Breadcrumbs on Centered Pages

Pages using the centered transparent layout should NOT have `<h1>` breadcrumb navigation. The header title and sidebar provide navigation context. Instead, add a heading inside the `.settings-card`:

```erb
<div class="settings-card">
  <h2>Edit Watering</h2>
  <%= render "form", ... %>
  <p><%= link_to "Discard", ..., class: 'link' %></p>
  <p><%= button_to "Delete", ..., class: 'buttonLinkDanger', ... %></p>
</div>
```

Action links (edit, delete, etc.) belong inside the card, not floating outside it.

## Progressive Disclosure (Toggle Sections)

For optional form fields revealed by a button click, group each toggle button with its field so visual ordering stays correct:

```erb
<div class="moisture-section">
  <!-- Pre group: button + field together -->
  <div>
    <button type="button" data-action="click->controller#togglePre"
            data-controller-target="preButton" class="buttonLink">
      Add Pre-Watering Moisture
    </button>
    <div data-controller-target="preField" style="display: none;">
      <!-- field content -->
      <button type="button" data-action="click->controller#hidePre"
              class="buttonLinkSmall">Remove</button>
    </div>
  </div>

  <!-- Post group: button + field together -->
  <div>
    <button type="button" data-action="click->controller#togglePost" ...>
      Add Post-Watering Moisture
    </button>
    <div data-controller-target="postField" style="display: none;">
      <!-- field content -->
    </div>
  </div>
</div>
```

**Never** put all toggle buttons in a shared header div separate from their fields — this causes the revealed field to appear after the other button, breaking visual order.

## Button Classes

| Class | Use |
|-------|-----|
| `.saveButton` | Primary submit buttons |
| `.buttonLink` | Action buttons styled as links (green background) |
| `.buttonLinkSmall` | Small inline action buttons (e.g., "Remove") |
| `.buttonLinkDanger` | Destructive action buttons (red) |
| `.plantButton` | Green pill linking to a plant |
| `.link` | Standard text links |

## Key CSS Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `--header-height` | `4.5rem` (desktop), `4rem` (mobile) | Header row height in body grid |
| `--card-max-width` | `650px` (resets to `none` at 750px) | Shared max-width for cards, banners, search |
| `--section-gradient` | Per-section | Header gradient background |
| `--section-color-start` | Per-section | Solid color for hamburger button background |

## Responsive Breakpoints

| Breakpoint | What changes |
|------------|-------------|
| `1550px` | Plants index switches from 1-column to 2-column grid |
| `900px` landscape + `500px` height | Compact sidebar logo |
| `750px` | `--card-max-width` disabled; `.info-card-grid` goes single column |
| `600px` | Mobile layout: sidebar hidden, hamburger fixed, header shrinks to 4rem |
| `500px` | Plant cards switch to stacked mobile layout |

## CSS Architecture Files

| File | Contains |
|------|----------|
| `app/assets/stylesheets/layout.sass` | Grid layout, header, sidebar, hamburger, expanded header with plant graphic, plant-graphic-banner (legacy) |
| `app/assets/stylesheets/shared.sass` | Cards, buttons, form styles, info-rows, per-controller form selectors, centered page patterns |
| `app/assets/stylesheets/plants.sass` | Plants index cards, filters, pagination, quick-water UI, 2-column breakpoint |
