# Layout Architecture, Design System & CSS Gotchas

SASS (sassc-rails). Covers the grid layout, the context-aware header, the sidebar, the dynamic
plant-graphic header, the design-system class vocabulary, and the CSS traps.

## Grid layout

- **`"sidebar header" / "sidebar main"`** — the sidebar spans both rows.
- **Context-aware header:** `display: grid`, single column; all children share the same grid
  cell. Gradient color and title change per controller section (Plants=green, Waterings=blue,
  Tanks=teal, etc.) via the `header_config` helper. `#headerTitle` is a direct child of `<header>`,
  truly centered independent of `#headerRight` (email/dropdown).
- **`header_config` keys:** `icon`, `title` (page-specific), `section_title` (generic, for
  hamburger), `gradient_class`, `nav_path` (always a valid section index URL), `plant_graphic`
  (show pages only).

## Sidebar

Three sections top-to-bottom:
1. `button.hamburgerToggle` — ☰ icon (absolutely positioned in a 4rem box, never moves during
   animation) + section title (fades via opacity).
2. `a.sidebarNav` > `#logoContainer` — tall section icon (16rem expanded via `--logo-size`,
   header-height minimized), always links to the section index.
3. `<nav>` — current section's sub-nav (`.indent`) at top; all sections vertically centered
   between `.fill` divs; locale switcher at bottom. Current section marked with `selected`.

- **States:** minimized = icon rail (4rem, emoji-only labels, hamburger title hidden); expanded =
  full 18rem with text labels.
- **FOUC prevention:** an inline `<script>` in `<head>` applies sidebar state before render; the
  hamburger icon uses absolute positioning so it never shifts during width transitions; the title
  uses opacity transitions.
- **Nav icons:** Plants uses `autofauna_icon.png` (`.nav-icon` class); other sections still use
  emoji (to be migrated).

## Dynamic plant-graphic header (plant/watering pages)

When `.header-plant-graphic` is present, the header expands from `--header-collapsed`
(`4.5rem` / `4rem` mobile) to `--header-expanded` (`14.5rem` desktop and mobile) with a single-row
grid. `dynamic_header_controller` (attached to `<main>`) intercepts wheel/touch events and smoothly
interpolates `--header-height`, `--graphic-opacity` (1→0), and `--title-opacity` (0→1) as CSS
custom properties on `<body>`.

- During collapse, `preventDefault()` stops actual scrolling so content stays in place; normal
  scrolling begins only after full collapse. Re-expansion happens when the user scrolls back to
  `scrollTop=0`.
- Skips activation if content fits without scrolling, but once collapse begins it always completes
  fully (**latched**). Skips entirely on pages without the `--header-expanded`/`--header-collapsed`
  variables (e.g. the plants index, which has `header_extra` but no `.header-plant-graphic`).
- `#headerRight` uses `align-self: center`. Header uses `overflow: visible` (not hidden) so the
  user dropdown can extend below it; `.header-plant-graphic` itself has `overflow: hidden` to clip
  during collapse. On mobile the hamburger spans the full `--header-height` for vertical centering.
- On mobile the controller tracks touch velocity and applies a friction-based rAF momentum
  animation on `touchend`; new touches cancel in-progress momentum.

**Legacy banner:** `.plant-graphic-banner` renders in `section#primary` before yield on plant/
watering show pages (inside `.settings-card` on plant edit). Uses `max-width: var(--card-max-width)`.
Prefer the header-graphic approach (`content_for :header_extra`) over this legacy banner.

## Plants-index header layout

A `display:contents` wrapper (in `header_extra`) promotes its children into the header grid
(`minmax(0,1fr) auto`, `align-items: start`). Row 1: `.header-top-row` (col 1; flex/wrap holding
`#headerSearch` + `.saved-searches-row`) and `#headerRight` (col 2). Row 2:
`.header-collapse-panel` (col 1/-1). `#headerTitle` is hidden; `#headerSearch` is
`max-width: var(--card-max-width)`. The header has `padding-bottom` and `section#primary` has
`padding-top` to reserve space for the floating rectangular `.filter-collapse-btn` handle
(~`4rem×1.6rem`) that straddles the header/main border. A circular `.card-fields-menu` cog (⚙️)
floats on that edge at the right corner. Plant counts live in the frame's `.plants-toolbar`, not
the header. (Full behavior: `docs/plants-index-ui.md`.)

## Shared CSS variables & breakpoints

- **`--card-max-width: 650px`** on body — shared by `.plant-graphic-banner`,
  `.info-card-grid:has(.details-section)`, and the plants-index search bar. Resets to `none` at
  ≤750px so content shrinks with the viewport.
- **Breakpoints:** ≤600px (mobile: sidebar top-aligned, hamburger fixed), ≤750px
  (`--card-max-width` disabled, `.info-card-grid` single column), ≤900px landscape with ≤500px
  height (compact sidebar logo).

## Design system (CSS classes)

| Component | Usage | Class |
|---|---|---|
| Resource card | Index list items (clickable) | `.resource-card` inside `.resource-cards` |
| Info card | Show-page detail display | `.info-card` > `.info-card-grid` > `.info-card-section` with `.info-row` |
| Settings card | Edit/New form wrapper | `.settings-card` |
| Danger card | Destructive actions | `.settings-card.danger` |

## CSS gotchas

- **Flex/grid `min-width: 0` rule:** any flex or grid child that should shrink below its content
  width needs `min-width: 0` — the default `min-width: auto` prevents shrinking and causes
  horizontal overflow that `overflow-x: clip` cannot fix. Applies throughout the layout chain:
  `main`, `section#primary`, `.info-card-section`, `.watering-text`, `.water-icon-link`,
  `.info-row .value`. Add it to every new flex/grid container with variable-width content.
- **`grid-template-rows: 0fr↔1fr` collapse (header search panel):** `.header-collapse-panel` is
  `display:grid; grid-template-rows: 0fr`, animated to `1fr` (via `.expanded` or
  `header:has(.filter-collapse-btn[aria-expanded="true"])`); inner `.header-collapse-inner` has
  `overflow:hidden; min-height:0`. **Do not put vertical padding on the collapsing element** —
  padding doesn't shrink with the `0fr` row, leaving a visible strip when collapsed (`overflow:hidden`
  clips children, not the element's own padding). Keep horizontal padding only on
  `.header-collapse-inner`; bottom spacing comes from content inside it.
- **CSS transition direction:** the `transition` on the **destination** state sets the duration.
  `transition: opacity 0.4s` on the base + `transition: opacity 0.1s` inside `[aria-busy]` gives a
  fast fade-out (0.1s → busy) and slow fade-in (0.4s → normal).
- **`form.button_to` display override:** `shared.sass` sets `form.button_to { display: inline-block }`.
  To override `display` on a `button_to` form inside a component, use a more specific selector
  (e.g. `.my-component form.button_to { display: flex }`).
- **`button_to`/`<button>` color inheritance:** `<button>` has a browser-default `color`
  (`buttontext`) that overrides inheritance. With `display: contents` on a
  `button[type="submit"]` inside a styled parent, add `color: inherit` so SVGs with
  `fill="currentColor"` pick up the parent's color.

See also the `display:contents` header-wrapper tag-balance gotcha in `docs/plants-index-ui.md`.
