import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "sourceSelect", "recipeSection",
    "recipeSelect", "batchSelect", "tdsField", "tdsButton", "tdsContainer",
    "unifiedBatchSelect", "recipeIdHidden",
    "volumeSection", "volumeButton", "volumeField", "unitsSelect"
  ]
  static values = { url: String, projectUrl: String }

  sourceChanged() {
    const sourceId = this.hasSourceSelectTarget ? this.sourceSelectTarget.value : null
    if (this.hasRecipeSectionTarget) {
      this.recipeSectionTarget.style.display = sourceId ? "none" : ""
    }
    if (sourceId && this.hasRecipeSelectTarget) {
      this.recipeSelectTarget.value = ""
      if (this.hasBatchSelectTarget) {
        this.batchSelectTarget.innerHTML = '<option value="">-- None --</option>'
      }
    }
  }


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

  // Unified batch select: one dropdown for recipe+batch
  unifiedBatchChanged() {
    if (!this.hasUnifiedBatchSelectTarget) return
    const selected = this.unifiedBatchSelectTarget.selectedOptions[0]
    if (!selected || !selected.value) {
      // No selection — clear recipe_id hidden
      if (this.hasRecipeIdHiddenTarget) this.recipeIdHiddenTarget.value = ""
      return
    }

    const recipeId = selected.dataset.recipeId || ""
    const batchTds = selected.dataset.tds
    const recipeDefaultTds = selected.dataset.recipeDefaultTds

    // Set hidden recipe_id
    if (this.hasRecipeIdHiddenTarget) {
      this.recipeIdHiddenTarget.value = recipeId
    }

    // Auto-fill TDS: prefer batch TDS, fall back to recipe default
    const tdsValue = (batchTds && batchTds !== "") ? batchTds
                   : (recipeDefaultTds && recipeDefaultTds !== "") ? recipeDefaultTds
                   : null

    if (tdsValue && this.hasTdsFieldTarget) {
      this.tdsFieldTarget.value = tdsValue
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
