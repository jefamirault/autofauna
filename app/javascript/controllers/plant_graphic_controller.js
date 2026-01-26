import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["nameInput", "graphicSelect", "preview"]
  static values = {
    suggestUrl: String,
    paths: Object
  }

  connect() {
    this.debounceTimer = null
    this.manuallySelected = false
    this.updatePreview()
  }

  nameChanged() {
    // Don't auto-suggest if user has manually selected a graphic
    if (this.manuallySelected) {
      return
    }

    // Clear existing timer
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer)
    }

    // Debounce the API call
    this.debounceTimer = setTimeout(() => {
      this.fetchGraphicSuggestion()
    }, 300)
  }

  async fetchGraphicSuggestion() {
    const name = this.nameInputTarget.value

    if (!name || name.trim() === "") {
      return
    }

    try {
      const url = `${this.suggestUrlValue}?name=${encodeURIComponent(name)}`
      const response = await fetch(url)
      const data = await response.json()

      if (data.graphic) {
        // Only update if user hasn't manually selected
        if (!this.manuallySelected) {
          this.graphicSelectTarget.value = data.graphic
          this.updatePreview()
        }
      }
    } catch (error) {
      console.error("Error fetching graphic suggestion:", error)
    }
  }

  graphicChanged() {
    this.manuallySelected = true
    this.updatePreview()
  }

  updatePreview() {
    const selectedGraphic = this.graphicSelectTarget.value

    if (selectedGraphic && selectedGraphic !== "" && this.pathsValue[selectedGraphic]) {
      this.previewTarget.src = this.pathsValue[selectedGraphic]
      this.previewTarget.style.display = "block"
    } else {
      this.previewTarget.style.display = "none"
    }
  }
}
