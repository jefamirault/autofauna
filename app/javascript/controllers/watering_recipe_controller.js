import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // Batch/TDS behavior here now serves only the plants-index bulk-water panel; the watering form
  // itself uses fertilizer-picker (which dispatches `tds` -> applyTds). Volume/TDS disclosure below
  // is shared by both.
  static targets = [
    "recipeSelect", "batchSelect", "tdsField", "tdsButton", "tdsContainer",
    "volumeSection", "volumeButton", "volumeField", "unitsSelect"
  ]
  static values = { url: String }

  recipeChanged() {
    const recipeId = this.hasRecipeSelectTarget ? this.recipeSelectTarget.value : null

    if (!recipeId) {
      if (this.hasBatchSelectTarget) {
        this.batchSelectTarget.innerHTML = '<option value="">-- None --</option>'
      }
      return
    }

    fetch(`${this.urlValue}?recipe_id=${recipeId}`)
      .then(response => response.json())
      .then(batches => {
        let options = '<option value="">-- None --</option>'
        batches.forEach(batch => {
          options += `<option value="${batch.id}" data-tds="${batch.tds}">${batch.label}</option>`
        })
        if (this.hasBatchSelectTarget) {
          this.batchSelectTarget.innerHTML = options
        }
      })
  }

  batchChanged() {
    if (!this.hasBatchSelectTarget) return
    const selected = this.batchSelectTarget.selectedOptions[0]
    if (selected && selected.dataset.tds) {
      this.tdsFieldTarget.value = selected.dataset.tds
      this.showTds()
    }
  }

  // Fired by fertilizer-picker on the watering form when a selection implies a TDS value.
  applyTds(event) {
    const tds = event.detail && event.detail.tds
    if (tds == null || tds === "") return
    if (this.hasTdsFieldTarget) {
      this.tdsFieldTarget.value = tds
      this.showTds()
    }
  }

  // Volume toggle
  showVolume() {
    if (this.hasVolumeSectionTarget) this.volumeSectionTarget.style.display = ""
    if (this.hasVolumeButtonTarget) this.volumeButtonTarget.style.display = "none"
    if (this.hasVolumeFieldTarget) this.volumeFieldTarget.focus()
  }

  hideVolume() {
    if (this.hasVolumeSectionTarget) this.volumeSectionTarget.style.display = "none"
    if (this.hasVolumeButtonTarget) this.volumeButtonTarget.style.display = ""
    if (this.hasVolumeFieldTarget) this.volumeFieldTarget.value = ""
  }

  toggleTds() {
    this.tdsContainerTarget.style.display = "block"
    this.tdsButtonTarget.style.display = "none"
  }

  hideTds() {
    this.tdsContainerTarget.style.display = "none"
    this.tdsButtonTarget.style.display = "inline-block"
    this.tdsFieldTarget.value = ""
  }

  showTds() {
    if (this.hasTdsContainerTarget) {
      this.tdsContainerTarget.style.display = "block"
    }
    if (this.hasTdsButtonTarget) {
      this.tdsButtonTarget.style.display = "none"
    }
  }
}
