import { Controller } from "@hotwired/stimulus"

// Below this many pixels of movement a pointerdown is a click, not a drag — otherwise a tap
// on a tray chip would fling it onto the canvas.
const DRAG_THRESHOLD = 4
const SAVE_DEBOUNCE = 250

// Canvas and tray heights are drag-resizable (CSS `resize: vertical`); remember them per device
// so the handles are worth using.
const SIZE_DEBOUNCE = 200
const CANVAS_HEIGHT_KEY = "location-diagram-canvas-height"
const TRAY_HEIGHT_KEY = "location-diagram-tray-height"

// Location show page: drag circular plant chips around a 2D canvas to mirror the real room.
//
// Positions are normalized 0.0-1.0 (chip *centers*), so a layout built on a phone reads the
// same on a desktop. Chips live either in the canvas (placed) or the tray (unplaced); a drag
// between the two is what places or unplaces a plant. Saves are batched and debounced —
// dragging four chips in a row sends one PATCH.
//
// Pointer events (not mouse/touch pairs) so one code path covers finger and cursor. Chips
// only become draggable in "Arrange" mode, which viewers never get.
export default class extends Controller {
  static targets = [
    "canvas", "chip", "tray", "trayChips", "canvasEmpty",
    "backdrop", "backdropButton", "editButton", "status", "hint"
  ]
  static values = { url: String, editable: Boolean }

  connect() {
    this.editing = false
    this.drag = null
    this.pending = new Map()
    this.saveTimer = null
    this.highlights = { group: new Set(), recipe: new Set() }
    this._onPointerMove = this._onPointerMove.bind(this)
    this._onPointerUp = this._onPointerUp.bind(this)
    this._onPointerCancel = this._onPointerCancel.bind(this)
    this.restoreSizes()
    this.watchSizes()
    this.refreshEmptyStates()
  }

  disconnect() {
    this.cancelDrag()
    this.sizeObserver?.disconnect()
    if (this.saveTimer) clearTimeout(this.saveTimer)
    if (this.sizeTimer) clearTimeout(this.sizeTimer)
  }

  // ---- modes -------------------------------------------------------------

  toggleEdit() {
    if (!this.editableValue) return

    this.editing = !this.editing
    this.element.classList.toggle("is-editing", this.editing)

    if (this.hasEditButtonTarget) {
      this.editButtonTarget.setAttribute("aria-pressed", String(this.editing))
      this.editButtonTarget.textContent = this.editing ? "✓ Done" : "✏️ Arrange"
    }
    if (this.hasHintTarget) {
      this.hintTarget.textContent = this.editing
        ? "Drag each plant to where it really sits. Arrow keys nudge the focused plant."
        : "Tap Arrange, then drag each plant to where it really sits."
    }
    // The tray is the only way to reach unplaced plants, so it stays visible while
    // arranging even when empty — it doubles as the drop zone for removing a chip.
    this.refreshEmptyStates()
  }

  toggleBackdrop() {
    if (!this.hasBackdropTarget) return

    const showing = this.element.classList.toggle("show-backdrop")
    if (this.hasBackdropButtonTarget) {
      this.backdropButtonTarget.setAttribute("aria-pressed", String(showing))
    }
  }

  // ---- resizable canvas & tray -------------------------------------------
  //
  // Both areas carry CSS `resize: vertical` above 750px. The browser writes an *inline* height
  // when you drag a handle, so "has an inline height" is exactly "the user chose this size".
  // CSS-driven changes — the tray opening and shortening the canvas, a window resize — never
  // set one, which is what keeps them from being persisted as if they were deliberate.

  restoreSizes() {
    if (!this.resizable) return

    const canvas = localStorage.getItem(CANVAS_HEIGHT_KEY)
    const tray = localStorage.getItem(TRAY_HEIGHT_KEY)
    if (canvas && this.hasCanvasTarget) this.canvasTarget.style.height = canvas
    if (tray && this.hasTrayTarget) this.trayTarget.style.height = tray
  }

  watchSizes() {
    if (!this.resizable || typeof ResizeObserver === "undefined") return

    // Reads only — writing to the DOM from here would loop the observer.
    this.sizeObserver = new ResizeObserver(() => {
      if (this.sizeTimer) clearTimeout(this.sizeTimer)
      this.sizeTimer = setTimeout(() => this.saveSizes(), SIZE_DEBOUNCE)
    })
    if (this.hasCanvasTarget) this.sizeObserver.observe(this.canvasTarget)
    if (this.hasTrayTarget) this.sizeObserver.observe(this.trayTarget)
  }

  saveSizes() {
    this.storeSize(CANVAS_HEIGHT_KEY, this.hasCanvasTarget && this.canvasTarget.style.height)
    this.storeSize(TRAY_HEIGHT_KEY, this.hasTrayTarget && this.trayTarget.style.height)
  }

  storeSize(key, height) {
    height ? localStorage.setItem(key, height) : localStorage.removeItem(key)
  }

  // Only above 750px, where the stylesheet gives both areas a definite height to resize from.
  // Below that the canvas is aspect-ratio'd and the tray flows, so a stored pixel height would
  // just be wrong — it's left alone for the next desktop visit.
  get resizable() {
    return window.matchMedia("(min-width: 751px)").matches
  }

  // ---- dragging ----------------------------------------------------------

  startDrag(event) {
    if (!this.editing || event.button > 0) return

    const chip = event.currentTarget
    event.preventDefault()

    const rect = chip.getBoundingClientRect()
    this.drag = {
      chip,
      pointerId: event.pointerId,
      startX: event.clientX,
      startY: event.clientY,
      // Pointer → chip centre, so grabbing a chip by its edge doesn't snap it under the cursor.
      grabX: rect.left + rect.width / 2 - event.clientX,
      grabY: rect.top + rect.height / 2 - event.clientY,
      // Enough to put the chip back untouched if the gesture is cancelled.
      fromLeft: chip.style.left,
      fromTop: chip.style.top,
      moved: false
    }

    chip.setPointerCapture(event.pointerId)
    chip.addEventListener("pointermove", this._onPointerMove)
    chip.addEventListener("pointerup", this._onPointerUp)
    chip.addEventListener("pointercancel", this._onPointerCancel)
  }

  _onPointerMove(event) {
    if (!this.drag || event.pointerId !== this.drag.pointerId) return

    if (!this.drag.moved) {
      const travelled = Math.hypot(event.clientX - this.drag.startX, event.clientY - this.drag.startY)
      if (travelled < DRAG_THRESHOLD) return

      // Lift. `.is-dragging` pins the chip to the viewport (position: fixed) and it stays in
      // whichever container it started in until the drop. Moving it into the canvas here
      // instead is what made a tray chip flash onto the canvas edge — the coordinates were
      // clamped to the canvas, so a pointer still down in the tray put the chip at the frame's
      // bottom edge, looking like a duplicate had appeared.
      this.drag.moved = true
      this.drag.chip.classList.add("is-dragging")
    }

    this.drag.chip.style.left = `${event.clientX + this.drag.grabX}px`
    this.drag.chip.style.top = `${event.clientY + this.drag.grabY}px`
  }

  _onPointerUp(event) {
    if (!this.drag || event.pointerId !== this.drag.pointerId) return

    const { chip, moved, grabX, grabY } = this.drag
    const overTray = this.isOverTray(event)
    this.cancelDrag()

    if (!moved) return

    if (overTray) {
      this.unplace(chip)
    } else {
      this.place(chip, event.clientX + grabX, event.clientY + grabY)
    }
    this.refreshEmptyStates()
  }

  _onPointerCancel() {
    const drag = this.drag
    this.cancelDrag()
    if (!drag?.moved) return

    // Nothing was committed. Dropping `.is-dragging` un-pins the chip, so restoring the
    // inline coordinates is enough — it never left its container.
    drag.chip.style.left = drag.fromLeft
    drag.chip.style.top = drag.fromTop
  }

  cancelDrag() {
    if (!this.drag) return

    const { chip, pointerId } = this.drag
    chip.classList.remove("is-dragging")
    chip.removeEventListener("pointermove", this._onPointerMove)
    chip.removeEventListener("pointerup", this._onPointerUp)
    chip.removeEventListener("pointercancel", this._onPointerCancel)
    if (chip.hasPointerCapture?.(pointerId)) chip.releasePointerCapture(pointerId)
    this.drag = null
  }

  // A click fires after every drag; swallow it so arranging never navigates away. Also
  // swallow plain clicks while arranging — in that mode a chip is a handle, not a link.
  chipClick(event) {
    if (this.editing) event.preventDefault()
  }

  nudge(event) {
    if (!this.editing) return

    const step = event.shiftKey ? 0.005 : 0.02
    const deltas = {
      ArrowLeft: [-step, 0], ArrowRight: [step, 0],
      ArrowUp: [0, -step], ArrowDown: [0, step]
    }
    const delta = deltas[event.key]
    if (!delta) return

    event.preventDefault()
    const chip = event.currentTarget
    if (!this.canvasTarget.contains(chip)) this.canvasTarget.appendChild(chip)

    const current = this.chipPosition(chip)
    const bounds = this.chipBounds(chip)
    const x = this.clamp(current.x + delta[0], bounds.halfW, 1 - bounds.halfW)
    const y = this.clamp(current.y + delta[1], bounds.halfH, 1 - bounds.halfH)

    chip.style.left = `${(x * 100).toFixed(2)}%`
    chip.style.top = `${(y * 100).toFixed(2)}%`
    this.queueSave(chip.dataset.plantId, x, y)
    this.refreshEmptyStates()
  }

  // ---- legend highlighting ----------------------------------------------

  toggleHighlight(event) {
    const button = event.currentTarget
    const { kind, id } = button.dataset
    const set = this.highlights[kind]
    if (!set) return

    const active = !set.has(id)
    active ? set.add(id) : set.delete(id)
    button.classList.toggle("is-active", active)
    button.setAttribute("aria-pressed", String(active))
    this.applyHighlights()
  }

  applyHighlights() {
    const any = this.highlights.group.size > 0 || this.highlights.recipe.size > 0
    this.element.classList.toggle("is-highlighting", any)

    this.chipTargets.forEach((chip) => {
      chip.classList.toggle("is-match", any && this.chipMatches(chip))
    })
  }

  chipMatches(chip) {
    const groups = (chip.dataset.groupIds || "").split(" ").filter(Boolean)
    const recipes = (chip.dataset.recipeIds || "").split(" ").filter(Boolean)
    return groups.some((id) => this.highlights.group.has(id)) ||
      recipes.some((id) => this.highlights.recipe.has(id))
  }

  // ---- persistence -------------------------------------------------------

  queueSave(plantId, x, y) {
    this.pending.set(plantId, { id: Number(plantId), x, y })
    this.setStatus("Saving…")

    if (this.saveTimer) clearTimeout(this.saveTimer)
    this.saveTimer = setTimeout(() => this.flush(), SAVE_DEBOUNCE)
  }

  async flush() {
    if (this.pending.size === 0) return

    const positions = Array.from(this.pending.values())
    this.pending.clear()

    try {
      const response = await fetch(this.urlValue, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": this.csrfToken
        },
        body: JSON.stringify({ positions })
      })
      if (!response.ok) throw new Error(response.statusText)
      this.setStatus("Layout saved.")
    } catch (error) {
      this.setStatus("Couldn't save the layout — check your connection and try again.", true)
    }
  }

  get csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content || ""
  }

  // ---- helpers -----------------------------------------------------------

  unplace(chip) {
    if (!this.hasTrayChipsTarget) return

    chip.style.left = ""
    chip.style.top = ""
    this.trayBucketFor(chip).appendChild(chip)
    this.queueSave(chip.dataset.plantId, null, null)
  }

  // The tray is grouped by fertilizer recipe, so a chip has to return to its own group. The
  // primary recipe leads `recipeIds` (plant_recipes is position-ordered), and the partial
  // renders a bucket for every recipe in the location, so there's always one to land in.
  trayBucketFor(chip) {
    const primaryRecipe = (chip.dataset.recipeIds || "").split(" ")[0] || ""
    const bucket = this.trayChipsTarget
      .querySelector(`[data-recipe-group="${CSS.escape(primaryRecipe)}"] .diagram-tray-group-chips`)
    return bucket || this.trayChipsTarget
  }

  // Commit a drop: the chip's centre in viewport pixels → normalized canvas coordinates,
  // clamped so no part of the chip hangs off the frame.
  place(chip, centreX, centreY) {
    const rect = this.canvasTarget.getBoundingClientRect()
    const bounds = this.chipBounds(chip, rect)
    const x = this.clamp((centreX - rect.left) / rect.width, bounds.halfW, 1 - bounds.halfW)
    const y = this.clamp((centreY - rect.top) / rect.height, bounds.halfH, 1 - bounds.halfH)

    this.canvasTarget.appendChild(chip)
    chip.style.left = `${(x * 100).toFixed(2)}%`
    chip.style.top = `${(y * 100).toFixed(2)}%`
    this.queueSave(chip.dataset.plantId, x, y)
  }

  chipBounds(chip, rect = this.canvasTarget.getBoundingClientRect()) {
    return {
      halfW: rect.width ? chip.offsetWidth / 2 / rect.width : 0,
      halfH: rect.height ? chip.offsetHeight / 2 / rect.height : 0
    }
  }

  chipPosition(chip) {
    return {
      x: (parseFloat(chip.style.left) || 50) / 100,
      y: (parseFloat(chip.style.top) || 50) / 100
    }
  }

  isOverTray(event) {
    if (!this.hasTrayTarget || this.trayTarget.hidden) return false

    const rect = this.trayTarget.getBoundingClientRect()
    return event.clientX >= rect.left && event.clientX <= rect.right &&
      event.clientY >= rect.top && event.clientY <= rect.bottom
  }

  clamp(value, min, max) {
    if (min > max) return (min + max) / 2
    return Math.min(Math.max(value, min), max)
  }

  refreshEmptyStates() {
    if (this.hasCanvasEmptyTarget) {
      this.canvasEmptyTarget.hidden = this.canvasTarget.querySelector(".diagram-chip") !== null
    }
    if (this.hasTrayTarget && this.hasTrayChipsTarget) {
      // A recipe group whose plants are all placed shouldn't leave its heading behind.
      this.trayChipsTarget.querySelectorAll(".diagram-tray-group").forEach((group) => {
        group.hidden = group.querySelector(".diagram-chip") === null
      })

      const empty = this.trayChipsTarget.querySelector(".diagram-chip") === null
      this.trayTarget.hidden = empty && !this.editing
    }
  }

  setStatus(message, isError = false) {
    if (!this.hasStatusTarget) return

    this.statusTarget.textContent = message
    this.statusTarget.classList.toggle("is-error", isError)
  }
}
