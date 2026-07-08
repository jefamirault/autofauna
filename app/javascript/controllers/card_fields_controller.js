import { Controller } from "@hotwired/stimulus"

// Cog menu on the plants index. Two jobs:
//   1. Show/hide individual attribute lines on the plant cards (checkboxes).
//   2. Reorder those lines by dragging rows on an example preview card.
// Both preferences are enforced on every real card via a single injected
// <style> of global CSS rules (display:none + grid `order`), so they survive
// display-mode switches, pagination, and Turbo Stream replaces. Preferences
// persist per-device in localStorage.
const HIDDEN_KEY = "plant-card-hidden-lines"
const ORDER_KEY = "plant-card-line-order"
const STYLE_ID = "plant-card-line-toggles"

export default class extends Controller {
  static targets = ["menu", "checkbox", "rows", "previewRow", "previewLine"]

  connect() {
    this.closeOnOutsideClick = this.closeOnOutsideClick.bind(this)
    this._onPointerMove = this._onPointerMove.bind(this)
    this._onPointerUp = this._onPointerUp.bind(this)
    document.addEventListener("click", this.closeOnOutsideClick)

    this._hidden = this._readHidden()
    this._order = this._readOrder()

    this._applyOrderToPreview()
    this._syncCheckboxes()
    this._syncPreviewVisibility()
    this._applyStyles()
  }

  disconnect() {
    document.removeEventListener("click", this.closeOnOutsideClick)
    document.removeEventListener("pointermove", this._onPointerMove)
    document.removeEventListener("pointerup", this._onPointerUp)
  }

  toggle(event) {
    event.stopPropagation()
    this.menuTarget.classList.toggle("hidden")
  }

  closeOnOutsideClick(event) {
    if (this._dragging) return
    if (!this.element.contains(event.target)) {
      this.menuTarget.classList.add("hidden")
    }
  }

  // ----- Show / hide (checkboxes) -----
  change() {
    const hidden = new Set()
    this.checkboxTargets.forEach((cb) => {
      if (!cb.checked) hidden.add(cb.dataset.lineClass)
    })
    this._hidden = hidden
    localStorage.setItem(HIDDEN_KEY, JSON.stringify([...hidden]))
    this._syncPreviewVisibility()
    this._applyStyles()
  }

  // ----- Drag reorder (preview) -----
  dragStart(event) {
    const row = event.target.closest(".cfp-row")
    if (!row) return
    this._dragging = true
    this._dragEl = row
    row.classList.add("dragging")
    if (event.pointerId != null && row.setPointerCapture) {
      row.setPointerCapture(event.pointerId)
    }
    document.addEventListener("pointermove", this._onPointerMove)
    document.addEventListener("pointerup", this._onPointerUp)
    event.preventDefault()
  }

  _onPointerMove(event) {
    if (!this._dragEl) return
    const y = event.clientY
    const dragRect = this._dragEl.getBoundingClientRect()
    const siblings = this.previewRowTargets.filter(
      (r) => r !== this._dragEl && !r.classList.contains("cfp-hidden")
    )
    for (const sib of siblings) {
      const rect = sib.getBoundingClientRect()
      const mid = rect.top + rect.height / 2
      if (y < mid && dragRect.top > rect.top) {
        this.rowsTarget.insertBefore(this._dragEl, sib)
        break
      }
      if (y > mid && dragRect.top < rect.top) {
        this.rowsTarget.insertBefore(this._dragEl, sib.nextSibling)
        break
      }
    }
  }

  _onPointerUp() {
    document.removeEventListener("pointermove", this._onPointerMove)
    document.removeEventListener("pointerup", this._onPointerUp)
    if (!this._dragEl) return
    this._dragEl.classList.remove("dragging")
    this._dragEl = null
    // Keep the drag flag set through this tick so the synthetic click that
    // follows pointerup doesn't get treated as an outside click.
    setTimeout(() => { this._dragging = false }, 0)

    this._order = this.previewRowTargets.map((r) => r.dataset.lineClass)
    localStorage.setItem(ORDER_KEY, JSON.stringify(this._order))
    this._applyStyles()
  }

  // ----- Helpers -----
  _defaultOrder() {
    return this.previewRowTargets.map((r) => r.dataset.lineClass)
  }

  _readHidden() {
    try {
      return new Set(JSON.parse(localStorage.getItem(HIDDEN_KEY)) || [])
    } catch (e) {
      return new Set()
    }
  }

  _readOrder() {
    const existing = this._defaultOrder()
    let saved = []
    try {
      saved = JSON.parse(localStorage.getItem(ORDER_KEY)) || []
    } catch (e) {
      saved = []
    }
    const ordered = saved.filter((c) => existing.includes(c))
    existing.forEach((c) => { if (!ordered.includes(c)) ordered.push(c) })
    return ordered
  }

  _applyOrderToPreview() {
    if (!this.hasRowsTarget) return
    this._order.forEach((cls) => {
      const row = this.previewRowTargets.find((r) => r.dataset.lineClass === cls)
      if (row) this.rowsTarget.appendChild(row)
    })
  }

  _syncCheckboxes() {
    this.checkboxTargets.forEach((cb) => {
      cb.checked = !this._hidden.has(cb.dataset.lineClass)
    })
  }

  _syncPreviewVisibility() {
    const toggle = (el) =>
      el.classList.toggle("cfp-hidden", this._hidden.has(el.dataset.lineClass))
    this.previewRowTargets.forEach(toggle)
    this.previewLineTargets.forEach(toggle)
  }

  _applyStyles() {
    let style = document.getElementById(STYLE_ID)
    if (!style) {
      style = document.createElement("style")
      style.id = STYLE_ID
      document.head.appendChild(style)
    }
    const rules = []
    this._hidden.forEach((cls) => {
      rules.push(`.plant-card .${cls}{display:none !important}`)
    })
    // The watering-window gauge belongs to the "Next watering" line — hide them together.
    if (this._hidden.has("plant-card-watering")) {
      rules.push(`.plant-card .plant-card-gauge{display:none !important}`)
    }
    this._order.forEach((cls, i) => {
      rules.push(`.plant-card .${cls}{order:${i}}`)
    })
    style.textContent = rules.join("")
  }
}
