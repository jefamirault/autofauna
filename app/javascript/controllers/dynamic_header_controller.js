import { Controller } from "@hotwired/stimulus"

// Continuously interpolates the header between expanded and collapsed states.
//
// Phase 1 (collapse): Intercepts wheel/touch events and prevents actual scrolling.
// Only the header shrinks — content stays visually in place.
//
// Phase 2 (normal): Header fully collapsed, normal scrolling resumes.
//
// When the user scrolls back up to scrollTop=0 and keeps going, the header
// re-expands (Phase 1 in reverse) before content can scroll further.
export default class extends Controller {
  connect() {
    this._readDimensions()

    // Only activate on pages with the expandable plant graphic header.
    // Other pages (e.g. plants index) have header_extra for the search bar
    // but no --header-expanded/--header-collapsed CSS variables.
    if (!this._scrollRange || isNaN(this._scrollRange) || this._scrollRange <= 0) return

    this._active = true
    this._delta = 0 // accumulated collapse progress in px

    this._wheelHandler = this._onWheel.bind(this)
    this._touchStartHandler = this._onTouchStart.bind(this)
    this._touchMoveHandler = this._onTouchMove.bind(this)

    this.element.addEventListener("wheel", this._wheelHandler, { passive: false })
    this.element.addEventListener("touchstart", this._touchStartHandler, { passive: true })
    this.element.addEventListener("touchmove", this._touchMoveHandler, { passive: false })

    this._update()
  }

  disconnect() {
    if (!this._active) return
    this.element.removeEventListener("wheel", this._wheelHandler)
    this.element.removeEventListener("touchstart", this._touchStartHandler)
    this.element.removeEventListener("touchmove", this._touchMoveHandler)
    document.body.style.removeProperty("--header-height")
    document.body.style.removeProperty("--graphic-opacity")
    document.body.style.removeProperty("--title-opacity")
  }

  _readDimensions() {
    const style = getComputedStyle(document.body)
    const rem = parseFloat(getComputedStyle(document.documentElement).fontSize)
    const expanded = parseFloat(style.getPropertyValue("--header-expanded")) * rem
    const collapsed = parseFloat(style.getPropertyValue("--header-collapsed")) * rem
    this._expandedPx = expanded
    this._collapsedPx = collapsed
    this._scrollRange = expanded - collapsed
  }

  _shouldCollapse() {
    // Once collapse has started, always allow it to finish.
    // Otherwise, only start collapsing if content overflows <main>.
    if (this._delta > 0) return true
    return this.element.scrollHeight > this.element.clientHeight
  }

  _onWheel(e) {
    if (e.deltaY > 0 && this._delta < this._scrollRange && this._shouldCollapse()) {
      // Scrolling down while header not fully collapsed — absorb into collapse
      e.preventDefault()
      this._delta = Math.min(this._scrollRange, this._delta + e.deltaY)
      this._update()
    } else if (e.deltaY < 0 && this._delta > 0 && this.element.scrollTop <= 0) {
      // Scrolling up at top of content — expand header
      e.preventDefault()
      this._delta = Math.max(0, this._delta + e.deltaY)
      this._update()
    }
  }

  _onTouchStart(e) {
    if (e.touches.length === 1) {
      this._touchY = e.touches[0].clientY
    }
  }

  _onTouchMove(e) {
    if (e.touches.length !== 1 || this._touchY == null) return
    const currentY = e.touches[0].clientY
    const deltaY = this._touchY - currentY // positive = scrolling down
    this._touchY = currentY

    if (deltaY > 0 && this._delta < this._scrollRange && this._shouldCollapse()) {
      e.preventDefault()
      this._delta = Math.min(this._scrollRange, this._delta + deltaY)
      this._update()
    } else if (deltaY < 0 && this._delta > 0 && this.element.scrollTop <= 0) {
      e.preventDefault()
      this._delta = Math.max(0, this._delta + deltaY)
      this._update()
    }
  }

  _update() {
    const progress = this._delta / this._scrollRange
    const height = this._expandedPx - (progress * this._scrollRange)
    document.body.style.setProperty("--header-height", height + "px")
    document.body.style.setProperty("--graphic-opacity", 1 - progress)
    document.body.style.setProperty("--title-opacity", progress)
  }
}
