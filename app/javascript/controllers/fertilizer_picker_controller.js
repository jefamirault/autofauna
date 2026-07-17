import { Controller } from "@hotwired/stimulus"

// Unified fertilizer picker (#113). One chip row + a searchable "More…" panel drive three hidden
// fields (recipe_source_id, recipe_id, recipe_batch_id). Source and recipe are mutually exclusive;
// picking a recipe auto-resolves its active batch and dispatches a `tds` event for the sibling
// watering-recipe controller to autofill. All items are server-rendered, so there is no fetch.
export default class extends Controller {
  static targets = [
    "sourceIdField", "recipeIdField", "batchIdField",
    "chipRow", "chip",
    "panel", "searchInput", "listRow", "groupHeader",
    "batchRow", "batchSelect"
  ]

  connect() {
    // Server sets the hidden fields (new / edit / param-prefill) — restore the batch UI to match.
    const recipeId = this.recipeIdFieldTarget.value
    if (recipeId) {
      const row = this.rowFor("recipe", recipeId)
      if (row) this.syncBatchRow(this.batchesOf(row), this.batchIdFieldTarget.value)
    }
  }

  // ─── Selection ─────────────────────────────────────────────────────────────

  pick(event) {
    const el = event.currentTarget
    const kind = el.dataset.kind
    const id = el.dataset.id || ""
    const fromPanel = el.classList.contains("fertilizer-picker-row")

    if (kind === "none") {
      this.setFields({ source: "", recipe: "", batch: "" })
      this.hideBatchRow()
    } else if (kind === "source") {
      this.setFields({ source: id, recipe: "", batch: "" })
      this.hideBatchRow()
    } else if (kind === "recipe") {
      const batches = this.batchesOf(el)
      const chosen = batches[0] || null // ordered most-recent first
      this.setFields({ source: "", recipe: id, batch: chosen ? chosen.id : "" })
      this.syncBatchRow(batches, chosen ? String(chosen.id) : "")
      this.emitTds(chosen ? chosen.tds : null, el.dataset.defaultTds)
    }

    this.selectChip(kind, id)

    if (fromPanel) {
      this.closePanel()
      this.searchInputTarget.value = ""
      this.filterList("")
    }
  }

  setFields({ source, recipe, batch }) {
    this.sourceIdFieldTarget.value = source
    this.recipeIdFieldTarget.value = recipe
    this.batchIdFieldTarget.value = batch
  }

  // Mark the matching chip selected, creating one from its panel row when it isn't already shown.
  selectChip(kind, id) {
    let chip = this.chipRowTarget.querySelector(
      kind === "none"
        ? `.suggestion-chip[data-kind="none"]`
        : `.suggestion-chip[data-kind="${kind}"][data-id="${id}"]`
    )
    if (!chip && kind !== "none") chip = this.createChip(kind, id)

    this.chipRowTarget.querySelectorAll(".suggestion-chip").forEach(c => c.classList.remove("selected"))
    if (chip) chip.classList.add("selected")
  }

  createChip(kind, id) {
    const row = this.rowFor(kind, id)
    if (!row) return null
    const chip = document.createElement("button")
    chip.type = "button"
    chip.className = "suggestion-chip"
    chip.dataset.fertilizerPickerTarget = "chip"
    chip.dataset.action = "click->fertilizer-picker#pick"
    chip.dataset.kind = kind
    chip.dataset.id = id
    if (row.dataset.batches) chip.dataset.batches = row.dataset.batches
    if (row.dataset.defaultTds) chip.dataset.defaultTds = row.dataset.defaultTds
    chip.innerHTML = row.innerHTML
    this.moreButton().insertAdjacentElement("beforebegin", chip)
    return chip
  }

  // ─── Batch resolution ────────────────────────────────────────────────────────

  batchChanged() {
    const opt = this.batchSelectTarget.selectedOptions[0]
    if (!opt) return
    this.batchIdFieldTarget.value = opt.value
    this.emitTds(opt.dataset.tds, this.selectedRecipeDefaultTds())
  }

  syncBatchRow(batches, selectedId) {
    if (batches.length >= 2) {
      this.batchSelectTarget.innerHTML = batches
        .map(b => `<option value="${b.id}" data-tds="${b.tds ?? ""}">${this.escape(b.label)}</option>`)
        .join("")
      this.batchSelectTarget.value = selectedId
      this.batchRowTarget.style.display = ""
    } else {
      this.hideBatchRow()
    }
  }

  hideBatchRow() {
    this.batchRowTarget.style.display = "none"
    this.batchSelectTarget.innerHTML = ""
  }

  // TDS autofill: prefer the batch tds, fall back to the recipe default. The watering-recipe
  // controller (on the form element) listens for this and un-hides the TDS field.
  emitTds(batchTds, defaultTds) {
    const tds = (batchTds != null && batchTds !== "") ? batchTds
              : (defaultTds != null && defaultTds !== "") ? defaultTds
              : null
    if (tds != null) this.dispatch("tds", { detail: { tds } })
  }

  // ─── Panel + search ──────────────────────────────────────────────────────────

  togglePanel() {
    const open = this.panelTarget.style.display !== "none"
    if (open) {
      this.closePanel()
    } else {
      this.panelTarget.style.display = ""
      this.searchInputTarget.focus()
    }
  }

  closePanel() {
    this.panelTarget.style.display = "none"
  }

  search() {
    this.filterList(this.searchInputTarget.value.trim().toLowerCase())
  }

  filterList(term) {
    const visibleGroups = new Set()
    this.listRowTargets.forEach(row => {
      const match = !term || row.dataset.name.includes(term)
      row.style.display = match ? "" : "none"
      if (match) visibleGroups.add(row.dataset.group)
    })
    this.groupHeaderTargets.forEach(h => {
      h.style.display = visibleGroups.has(h.dataset.group) ? "" : "none"
    })
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  batchesOf(el) {
    try { return JSON.parse(el.dataset.batches || "[]") } catch { return [] }
  }

  rowFor(kind, id) {
    return this.listRowTargets.find(r => r.dataset.kind === kind && r.dataset.id === String(id))
  }

  selectedRecipeDefaultTds() {
    const row = this.rowFor("recipe", this.recipeIdFieldTarget.value)
    return row ? row.dataset.defaultTds : null
  }

  moreButton() {
    return this.chipRowTarget.querySelector(".fertilizer-picker-more")
  }

  escape(str) {
    const div = document.createElement("div")
    div.textContent = str
    return div.innerHTML
  }
}
