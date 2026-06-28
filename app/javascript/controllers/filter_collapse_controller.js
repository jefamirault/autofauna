import { Controller } from "@hotwired/stimulus"

// Collapsible header search-options panel. Uses a CSS class toggle (`.expanded`) rather
// than measuring/animating height in JS — the panel is a grid item whose height is hard
// to measure reliably, so the animation lives in CSS (grid-template-rows 0fr→1fr).
export default class extends Controller {
  static targets = ["filterRow", "toggleBtn"]

  connect() {
    this._expanded = false
    this._autoCollapsed = false
    this._suppressAutoCollapse = false
    this._apply()

    const main = document.querySelector('main')
    if (main) {
      this._main = main
      this._onScroll = this._handleScroll.bind(this)
      main.addEventListener('scroll', this._onScroll, { passive: true })
    }
  }

  disconnect() {
    if (this._main && this._onScroll) {
      this._main.removeEventListener('scroll', this._onScroll)
    }
  }

  toggle() {
    if (this._expanded) {
      this._autoCollapsed = false
      this._collapse()
    } else {
      this._suppressAutoCollapse = true
      this._expand()
      if (this._main) this._main.scrollTo({ top: 0, behavior: 'smooth' })
    }
  }

  _expand() {
    this._expanded = true
    this._apply()
  }

  _collapse() {
    this._expanded = false
    this._apply()
  }

  _apply() {
    if (this.hasFilterRowTarget) {
      this.filterRowTarget.classList.toggle('expanded', this._expanded)
    }
    if (this.hasToggleBtnTarget) {
      this.toggleBtnTarget.setAttribute('aria-expanded', String(this._expanded))
    }
  }

  // Auto-collapse when the content scrolls; re-expand when scrolled back to the top
  // (only if the collapse was automatic, never overriding a manual collapse).
  _handleScroll() {
    if (this._suppressAutoCollapse) {
      if (this._main.scrollTop <= 10) this._suppressAutoCollapse = false
      return
    }
    const scrolled = this._main.scrollTop > 10
    if (scrolled && this._expanded) {
      this._autoCollapsed = true
      this._collapse()
    } else if (!scrolled && !this._expanded && this._autoCollapsed) {
      this._autoCollapsed = false
      this._expand()
    }
  }
}
