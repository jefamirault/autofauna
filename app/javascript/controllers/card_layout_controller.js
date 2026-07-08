import { Controller } from "@hotwired/stimulus"

// Mobile layout toggles on the plants toolbar (visible ≤600px):
//   1. Column count: 1-column stacked cards (default) vs a 2-column gallery.
//   2. Photo size while in 1-column: full-width hero (default) vs compact.
// State lives as classes on <html> (plant-cols-2 / plant-img-compact) so it
// survives turbo-frame reloads of the results; prefs persist per-device in
// localStorage. The CSS in plants.sass scopes both classes to ≤600px, so
// desktop layouts are unaffected.
const COLS_KEY = "plant-mobile-columns"
const IMG_KEY = "plant-mobile-image"

export default class extends Controller {
  static targets = ["oneColBtn", "twoColBtn", "imgBtn"]

  connect() {
    this._apply()
  }

  useOneCol() {
    localStorage.setItem(COLS_KEY, "1")
    this._apply()
  }

  useTwoCol() {
    localStorage.setItem(COLS_KEY, "2")
    this._apply()
  }

  toggleImage() {
    const compact = localStorage.getItem(IMG_KEY) === "compact"
    localStorage.setItem(IMG_KEY, compact ? "full" : "compact")
    this._apply()
  }

  _apply() {
    const twoCols = localStorage.getItem(COLS_KEY) === "2"
    const compact = localStorage.getItem(IMG_KEY) === "compact"

    const root = document.documentElement
    root.classList.toggle("plant-cols-2", twoCols)
    root.classList.toggle("plant-img-compact", compact)

    this._press(this.oneColBtnTarget, !twoCols)
    this._press(this.twoColBtnTarget, twoCols)
    if (this.hasImgBtnTarget) {
      this._press(this.imgBtnTarget, compact)
      this.imgBtnTarget.title = compact
        ? this.imgBtnTarget.dataset.fullTitle
        : this.imgBtnTarget.dataset.compactTitle
    }
  }

  _press(btn, pressed) {
    btn.classList.toggle("active", pressed)
    btn.setAttribute("aria-pressed", String(pressed))
  }
}
