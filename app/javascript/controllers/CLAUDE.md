# Stimulus Controllers

Hotwire + Importmap (no Node/Webpack). Controllers register conventionally.

## Roster

| Controller | Purpose |
|---|---|
| `location_filter_controller` | Plants index: client-side filtering (location/recipe), display-mode switching, pagination, and the counts line ("Showing N" / "Selected X out of N"). Runs as **two coordinating instances** — see gotcha below |
| `filter_collapse_controller` | Plants index header: collapse/expand the search-options panel. Toggles `.expanded` on `.header-collapse-panel` + `aria-expanded` on the floating `.filter-collapse-btn`; CSS animates `grid-template-rows: 0fr↔1fr`. Default collapsed; auto-collapses when `<main>` scrolls, re-expands at top |
| `collapsible_filters_controller` | Expand/collapse filter button rows (localStorage) |
| `collapsible_group_controller` | Collapsible location/recipe groups (localStorage) |
| `sidebar_controller` | Sidebar minimize/expand (hamburgerButton target), mobile auto-close, icon-rail mode, touch/swipe |
| `dropdown_controller` | Header user dropdown menu |
| `locale_popup_controller` | Sidebar locale switcher popup |
| `header_search_controller` | Debounced auto-submit for search |
| `card_fields_controller` | Plants index cog menu (⚙️): show/hide plant-card attribute lines + drag-reorder on an example preview card (pointer → mouse+touch). Enforces prefs on every card via one injected `<style>`; persists to localStorage (`plant-card-hidden-lines`, `plant-card-line-order`) |
| `card_layout_controller` | Plants index toolbar (mobile-only, ≤600px): 1↔2 column toggle + photo-size toggle (1-col only). Stamps `plant-cols-2`/`plant-img-compact` on `<html>` (survives frame reloads; CSS scopes them to ≤600px); persists to localStorage (`plant-mobile-columns`, `plant-mobile-image`) |
| `plant_select_controller` | Plants index multi-select: mode toggle, whole-card click-to-select (`cardClick`, skips the watering column), per-card checkbox reveal (inline `display`), selection keyed by plant id (synced across triple-rendered cards), select-all over filtered set, per-group select-all (`selectGroup`, buttons in location/recipe group headers), bulk water/archive/set-location/create-group/add-to-group via a dynamically-built POST form. Calls sibling `location-filter#updateResultsCount` (`_refreshCount`) |
| `plant_graphic_controller` | Graphic selection with live preview and auto-matching by name |
| `watering_recipe_controller` | Dynamic batch dropdown on recipe change, auto-fill TDS |
| `watering_moisture_controller` | Progressive disclosure of pre/post moisture fields |
| `nested_form_controller` | Add/remove rows for nested attributes (recipes) |
| `push_notification_controller` | Push device list: inline enable/disable toggle, "This Device" detection, test button state, global toggle sync |
| `notification_settings_controller` | Notification card: collapse/expand, frequency settings, dirty tracking, global enable/disable toggle, test button state |
| `dynamic_header_controller` | Scroll-driven header collapse on plant/watering show/edit pages. Interpolates `--header-height`/`--graphic-opacity`/`--title-opacity`; momentum on mobile. Only activates when `--header-expanded`/`--header-collapsed` are defined. See `docs/layout-css.md` |
| `onboarding_controller` | Multi-step onboarding wizard. See `docs/feature-flags.md` |

## Gotchas

- **Dual `location-filter` instances (plants index).** The **outer** sits on the header's
  `display:contents` wrapper (owns the search input, location/recipe filter buttons, saved-search
  form); the **inner** sits inside `turbo-frame#plants-results` (owns cards, groups, pagination,
  the `.plants-toolbar` count targets). They coordinate via the `location-filter:apply` document
  event (carries `locations`, `recipes`, `currentPage`, `displayMode`) and
  `_crossTarget`/`_crossTargets` (which fall back to `document.querySelector`). Only the inner
  reconnects on frame reload; the outer persists. `updateResultsCount` runs only on the inner (the
  card owner); in `selection-mode` it renders "Selected X out of N" by reading the sibling
  `plant-select` controller via
  `application.getControllerForElementAndIdentifier(this.element, "plant-select")` (both share the
  frame wrapper element).
- **`button_to` puts `data:` on the `<form>`, not the `<button>`.** To target the actual button
  from Stimulus, wrap in a div with the target and use `querySelector("button[type='submit']")`.
- **`button_to` renders a `<form>` in the DOM.** `querySelector("form")` may match a `button_to`
  form instead of the intended one (e.g. the push card has `button_to "Forget"` forms before the
  frequency form). Prefer querying the specific input on `this.element` (e.g.
  `this.element.querySelector('input[type="time"]')`) or use Stimulus targets.
- **`display:contents` header-wrapper must be tag-balanced.** A mismatched tag inside it hoists
  trailing elements out of the wrapper, so their actions silently never bind. `btn.closest('[data-controller]')`
  reveals the real parent for debugging. Full write-up in `docs/plants-index-ui.md`.
- **Cross-controller events (notifications).** `notification-settings` dispatches
  `notification-enabled`/`notification-disabled` on the `push-notification` element; a
  `_suppressHeaderSync` flag prevents feedback loops. See `docs/notifications.md`.
