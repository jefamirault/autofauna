import { Controller } from "@hotwired/stimulus"

// Plants index: multi-select mode + bulk actions (water / group / location / archive).
// Selection is keyed by plant id and synced across the triple-rendered cards.
export default class extends Controller {
  static targets = ["checkbox", "count", "actionBar", "waterOptions", "modeBtn"]
  static values = {
    csrf: String,
    bulkWaterUrl: String,
    bulkArchiveUrl: String,
    bulkSetLocationUrl: String,
    createGroupUrl: String,
    addToGroupUrlTemplate: String,
    confirmArchive: { type: String, default: "Archive the selected plants?" }
  }

  connect() {
    this.selected = new Set()
    // Default to off: keep per-card checkboxes hidden until Select is toggled.
    // Driven via inline display so it doesn't depend on the app's compiled CSS being fresh.
    this._showCheckboxes(false)
    // On (re)connect we start in non-select mode — make sure the button reflects that.
    if (this.hasModeBtnTarget) this.modeBtnTarget.classList.remove("active")
  }

  toggleMode() {
    this.element.classList.toggle("selection-mode")
    const on = this.element.classList.contains("selection-mode")
    this._showCheckboxes(on)
    if (this.hasActionBarTarget) this.actionBarTarget.style.display = on ? "" : "none"
    if (this.hasModeBtnTarget) this.modeBtnTarget.classList.toggle("active", on)
    if (!on) this.clear()
    this._refreshCount()
  }

  // The header count line shows "Selected X out of N" in select mode and "Showing N"
  // otherwise — both rendered by the location-filter controller on this same element.
  _refreshCount() {
    const lf = this.application.getControllerForElementAndIdentifier(this.element, "location-filter")
    if (lf) lf.updateResultsCount()
  }

  _showCheckboxes(show) {
    // Inline display beats any (possibly stale) author CSS rule. When showing,
    // clear it so the `.selection-mode .plant-card-select` styling applies.
    this.element.querySelectorAll(".plant-card-select").forEach(el => {
      el.style.display = show ? "" : "none"
    })
  }

  toggle(event) {
    const id = event.currentTarget.dataset.plantId
    if (event.currentTarget.checked) {
      this.selected.add(id)
    } else {
      this.selected.delete(id)
    }
    this._syncCard(id)
    this._updateCount()
  }

  // In selection mode, clicking anywhere on the card (except the watering column and the
  // checkbox, which have their own behavior) toggles selection. The plant-show links are
  // disabled via CSS in selection mode, so their clicks fall through to here.
  cardClick(event) {
    if (!this.element.classList.contains("selection-mode")) return
    if (event.target.closest(".plant-card-water-wrap")) return
    if (event.target.closest(".plant-card-select")) return
    const id = event.currentTarget.id?.replace(/^plant_/, "")
    if (!id) return
    event.preventDefault()
    if (this.selected.has(id)) {
      this.selected.delete(id)
    } else {
      this.selected.add(id)
    }
    this._syncCard(id)
    this._updateCount()
  }

  // Select every plant matching the current search+filters (across all pages of the
  // currently visible display mode), ignoring pagination. Re-click toggles to clear.
  selectAll() {
    const container = this._visibleContainer()
    if (!container) return

    const cards = Array.from(container.querySelectorAll(".plant-card:not([data-filter-hidden])"))
    const ids = [...new Set(cards.map(c => c.id?.replace(/^plant_/, "")).filter(Boolean))]

    const allSelected = ids.length > 0 && ids.every(id => this.selected.has(id))
    if (allSelected) {
      this.clear()
      return
    }

    ids.forEach(id => {
      this.selected.add(id)
      this._syncCard(id)
    })
    this._updateCount()
  }

  clear() {
    const ids = [...this.selected]
    this.selected.clear()
    ids.forEach(id => this._syncCard(id))
    this._updateCount()
  }

  toggleWaterOptions() {
    if (!this.hasWaterOptionsTarget) return
    const el = this.waterOptionsTarget
    el.style.display = el.style.display === "none" ? "" : "none"
  }

  water() {
    if (!this._guard()) return
    const params = {}
    if (this.hasWaterOptionsTarget) {
      this.waterOptionsTarget.querySelectorAll('[name^="watering["]').forEach(input => {
        if (input.value !== "") params[input.name] = input.value
      })
    }
    this._submit(this.bulkWaterUrlValue, params)
    // bulk_water responds with a Turbo Stream that re-renders the cards in place.
    this.selected.clear()
    this._updateCount()
    this.element.classList.remove("selection-mode")
    this._showCheckboxes(false)
    if (this.hasActionBarTarget) this.actionBarTarget.style.display = "none"
    if (this.hasModeBtnTarget) this.modeBtnTarget.classList.remove("active")
  }

  archive() {
    if (!this._guard()) return
    if (!window.confirm(this.confirmArchiveValue)) return
    this._submit(this.bulkArchiveUrlValue, {})
  }

  createGroup() {
    if (!this._guard()) return
    this._submit(this.createGroupUrlValue, {})
  }

  addToGroup(event) {
    const groupId = event.currentTarget.value
    if (!groupId) return
    if (!this._guard()) { event.currentTarget.selectedIndex = 0; return }
    this._submit(this.addToGroupUrlTemplateValue.replace("__ID__", groupId), {})
  }

  setLocation(event) {
    const locationId = event.currentTarget.value
    if (locationId === "") return
    if (!this._guard()) { event.currentTarget.selectedIndex = 0; return }
    this._submit(this.bulkSetLocationUrlValue, { location_id: locationId })
  }

  // --- helpers ---

  _guard() {
    if (this.selected.size === 0) {
      const msg = this.hasCountTarget ? this.countTarget.dataset.empty : null
      window.alert(msg || "Select at least one plant first.")
      return false
    }
    return true
  }

  _syncCard(id) {
    const checked = this.selected.has(id)
    this.element.querySelectorAll(`[data-plant-id="${id}"]`).forEach(cb => {
      cb.checked = checked
      cb.closest(".plant-card")?.classList.toggle("selected", checked)
    })
  }

  _updateCount() {
    if (this.hasCountTarget) {
      const tmpl = this.countTarget.dataset.template
      this.countTarget.textContent = tmpl
        ? tmpl.replace("__COUNT__", this.selected.size)
        : `${this.selected.size} selected`
    }
    // Keep the header count line ("Selected X out of N") in sync.
    this._refreshCount()
  }

  _visibleContainer() {
    const containers = this.element.querySelectorAll(
      '[data-location-filter-target$="GroupsContainer"]'
    )
    return Array.from(containers).find(c => c.style.display !== "none")
  }

  _submit(url, params) {
    const form = document.createElement("form")
    form.method = "post"
    form.action = url
    form.style.display = "none"

    this._appendInput(form, "authenticity_token", this.csrfValue)
    this.selected.forEach(id => this._appendInput(form, "plant_ids[]", id))
    Object.entries(params).forEach(([name, value]) => this._appendInput(form, name, value))

    document.body.appendChild(form)
    form.requestSubmit()
    form.remove()
  }

  _appendInput(form, name, value) {
    const input = document.createElement("input")
    input.type = "hidden"
    input.name = name
    input.value = value
    form.appendChild(input)
  }
}
