import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["filterButton", "buttonContainer", "locationGroup", "resultsCount", "wateringCount", "totalCount"]
  static values = {
    displayMode: String,
    wateringTemplate: String,
    resultsTemplate: String,
    resultsSearchTemplate: String,
    searchTerm: String
  }

  connect() {
    this.selectedLocations = new Set()
  }

  toggleFilter(event) {
    const locationId = event.currentTarget.dataset.locationId
    if (this.selectedLocations.has(locationId)) {
      this.selectedLocations.delete(locationId)
    } else {
      this.selectedLocations.add(locationId)
    }
    this.applyFilter()
  }

  selectSingleLocation(event) {
    const locationId = event.currentTarget.dataset.locationId
    if (this.selectedLocations.size === 1 && this.selectedLocations.has(locationId)) {
      this.selectedLocations.clear()
    } else {
      this.selectedLocations = new Set([locationId])
    }
    this.applyFilter()
  }

  applyFilter() {
    this.updateButtonStates()
    this.reorderButtons()
    this.filterPlants()
    this.updateResultsCount()
  }

  updateButtonStates() {
    this.filterButtonTargets.forEach(button => {
      const locationId = button.dataset.locationId
      if (this.selectedLocations.has(locationId)) {
        button.classList.add("active")
      } else {
        button.classList.remove("active")
      }
    })
  }

  reorderButtons() {
    if (!this.hasButtonContainerTarget) return
    const container = this.buttonContainerTarget
    const buttons = this.filterButtonTargets.slice()

    buttons.sort((a, b) => {
      const aActive = this.selectedLocations.has(a.dataset.locationId) ? 0 : 1
      const bActive = this.selectedLocations.has(b.dataset.locationId) ? 0 : 1
      if (aActive !== bActive) return aActive - bActive
      return parseInt(b.dataset.locationCount) - parseInt(a.dataset.locationCount)
    })

    buttons.forEach(button => container.appendChild(button))
  }

  filterPlants() {
    const showAll = this.selectedLocations.size === 0

    if (this.displayModeValue === "location") {
      this.locationGroupTargets.forEach(group => {
        const locationId = group.dataset.locationId
        group.style.display = (showAll || this.selectedLocations.has(locationId)) ? "" : "none"
      })
    } else {
      const cards = this.element.querySelectorAll(".plant-card[data-location-id]")
      cards.forEach(card => {
        const locationId = card.dataset.locationId
        card.style.display = (showAll || this.selectedLocations.has(locationId)) ? "" : "none"
      })
    }
  }

  updateResultsCount() {
    if (!this.hasWateringCountTarget || !this.hasTotalCountTarget) return
    const showAll = this.selectedLocations.size === 0
    const cards = this.element.querySelectorAll(".plant-card[data-location-id]")

    let total = 0
    let needsWatering = 0

    cards.forEach(card => {
      const locationId = card.dataset.locationId
      const visible = showAll || this.selectedLocations.has(locationId)
      if (visible) {
        total++
        if (card.dataset.needsWatering === "true") {
          needsWatering++
        }
      }
    })

    // Update watering count (first line)
    const wateringText = this.wateringTemplateValue
      .replace("__NEEDS_WATERING__", needsWatering)
    this.wateringCountTarget.textContent = wateringText

    // Update total count (second line)
    let totalText
    if (this.searchTermValue) {
      totalText = this.resultsSearchTemplateValue
        .replace("__TOTAL__", total)
        .replace("__SEARCH_TERM__", this.searchTermValue)
    } else {
      totalText = this.resultsTemplateValue
        .replace("__TOTAL__", total)
    }

    // Preserve the "Clear Search" link if present
    const clearLink = this.totalCountTarget.querySelector("a")
    const clearLinkClone = clearLink ? clearLink.cloneNode(true) : null

    // Update the text content
    this.totalCountTarget.textContent = totalText

    // Re-append the clear link if it existed
    if (clearLinkClone) {
      this.totalCountTarget.appendChild(document.createTextNode(" - "))
      this.totalCountTarget.appendChild(clearLinkClone)
    }
  }

  clearSearch(event) {
    event.preventDefault()
    const searchInput = document.querySelector('#headerSearch input[type="search"]')
    if (searchInput) {
      searchInput.value = ""
      const form = document.querySelector('#headerSearch form')
      if (form) {
        form.requestSubmit()
      }
    }
  }
}
