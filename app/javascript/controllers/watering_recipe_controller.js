import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["recipeSelect", "batchSelect", "tdsField", "tdsButton", "tdsContainer"]
  static values = { url: String }

  recipeChanged() {
    const recipeId = this.recipeSelectTarget.value

    if (!recipeId) {
      this.batchSelectTarget.innerHTML = '<option value="">-- None --</option>'
      return
    }

    fetch(`${this.urlValue}?recipe_id=${recipeId}`)
      .then(response => response.json())
      .then(batches => {
        let options = '<option value="">-- None --</option>'
        batches.forEach(batch => {
          options += `<option value="${batch.id}" data-tds="${batch.tds}">${batch.label}</option>`
        })
        this.batchSelectTarget.innerHTML = options
      })
  }

  batchChanged() {
    const selected = this.batchSelectTarget.selectedOptions[0]
    if (selected && selected.dataset.tds) {
      this.tdsFieldTarget.value = selected.dataset.tds
      this.showTds()
    }
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
