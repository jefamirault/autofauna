import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["filterButton", "recipeFilterButton", "buttonContainer", "recipeButtonContainer", "locationGroup", "resultsCount", "wateringCount", "totalCount"]
  static values = {
    displayMode: String,
    wateringTemplate: String,
    resultsTemplate: String,
    resultsSearchTemplate: String,
    searchTerm: String
  }

  connect() {
    this.selectedLocations = new Set()
    this.selectedRecipes = new Set()
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
    const showAllLocations = this.selectedLocations.size === 0
    const showAllRecipes = this.selectedRecipes.size === 0

    if (this.displayModeValue === "location") {
      this.locationGroupTargets.forEach(group => {
        const locationId = group.dataset.locationId
        const locationMatch = showAllLocations || this.selectedLocations.has(locationId)

        if (locationMatch && !showAllRecipes) {
          const cards = group.querySelectorAll(".plant-card[data-recipe-id]")
          const hasMatchingRecipe = Array.from(cards).some(card =>
            this.selectedRecipes.has(card.dataset.recipeId)
          )
          group.style.display = hasMatchingRecipe ? "" : "none"

          cards.forEach(card => {
            const recipeId = card.dataset.recipeId
            card.style.display = this.selectedRecipes.has(recipeId) ? "" : "none"
          })
        } else if (locationMatch) {
          group.style.display = ""
          const cards = group.querySelectorAll(".plant-card[data-recipe-id]")
          cards.forEach(card => card.style.display = "")
        } else {
          group.style.display = "none"
        }
      })
    } else {
      const cards = this.element.querySelectorAll(".plant-card[data-location-id]")
      cards.forEach(card => {
        const locationId = card.dataset.locationId
        const recipeId = card.dataset.recipeId
        const locationMatch = showAllLocations || this.selectedLocations.has(locationId)
        const recipeMatch = showAllRecipes || this.selectedRecipes.has(recipeId)
        card.style.display = (locationMatch && recipeMatch) ? "" : "none"
      })
    }
  }

  updateResultsCount() {
    if (!this.hasWateringCountTarget || !this.hasTotalCountTarget) return
    const showAllLocations = this.selectedLocations.size === 0
    const showAllRecipes = this.selectedRecipes.size === 0
    const cards = this.element.querySelectorAll(".plant-card[data-location-id]")

    let total = 0
    let needsWatering = 0

    cards.forEach(card => {
      const locationId = card.dataset.locationId
      const recipeId = card.dataset.recipeId
      const locationMatch = showAllLocations || this.selectedLocations.has(locationId)
      const recipeMatch = showAllRecipes || this.selectedRecipes.has(recipeId)
      const visible = locationMatch && recipeMatch

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

  toggleRecipeFilter(event) {
    const recipeId = event.currentTarget.dataset.recipeId
    if (this.selectedRecipes.has(recipeId)) {
      this.selectedRecipes.delete(recipeId)
    } else {
      this.selectedRecipes.add(recipeId)
    }
    this.applyRecipeFilter()
  }

  applyRecipeFilter() {
    this.updateRecipeButtonStates()
    this.reorderRecipeButtons()
    this.filterPlants()
    this.updateResultsCount()
  }

  updateRecipeButtonStates() {
    if (!this.hasRecipeFilterButtonTarget) return
    this.recipeFilterButtonTargets.forEach(button => {
      const recipeId = button.dataset.recipeId
      if (this.selectedRecipes.has(recipeId)) {
        button.classList.add("active")
      } else {
        button.classList.remove("active")
      }
    })
  }

  reorderRecipeButtons() {
    if (!this.hasRecipeButtonContainerTarget) return
    const container = this.recipeButtonContainerTarget
    const buttons = this.recipeFilterButtonTargets.slice()

    buttons.sort((a, b) => {
      const aActive = this.selectedRecipes.has(a.dataset.recipeId) ? 0 : 1
      const bActive = this.selectedRecipes.has(b.dataset.recipeId) ? 0 : 1
      if (aActive !== bActive) return aActive - bActive
      return parseInt(b.dataset.recipeCount) - parseInt(a.dataset.recipeCount)
    })

    buttons.forEach(button => container.appendChild(button))
  }
}
