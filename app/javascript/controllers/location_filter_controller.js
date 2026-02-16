import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "filterButton", "recipeFilterButton", "buttonContainer", "recipeButtonContainer",
    "locationGroup", "recipeGroup", "resultsCount", "wateringCount", "totalCount",
    "searchInput", "clearSearchBtn", "wateringStatusButton", "wateringStatusContainer",
    "wateringGroup", "groupCount",
    "addStatusFilterBtn", "addRecipeFilterBtn", "addLocationFilterBtn",
    "locationFilterContainer", "recipeFilterContainer", "addFiltersContainer",
    "locationGroupsContainer", "recipeGroupsContainer", "wateringGroupsContainer"
  ]
  static values = {
    displayMode: String,
    wateringTemplate: String,
    resultsTemplate: String,
    resultsSearchTemplate: String,
    resultsFilteredTemplate: String,
    resultsFilteredSearchTemplate: String,
    searchTerm: String
  }

  connect() {
    this.selectedLocations = new Set()
    this.selectedRecipes = new Set()
    this.selectedWateringStatuses = new Set()
    this.updateSearchClearButton()
    this.updateAddFiltersVisibility()
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

    // Get the label, toggle button, and remove button to preserve them at the end
    const label = container.querySelector('.display-toggle-label')
    const toggleButton = container.querySelector('.location-filters-toggle')
    const removeButton = container.querySelector('.remove-filter-btn')

    const buttons = this.filterButtonTargets.slice()

    buttons.sort((a, b) => {
      const aActive = this.selectedLocations.has(a.dataset.locationId) ? 0 : 1
      const bActive = this.selectedLocations.has(b.dataset.locationId) ? 0 : 1
      if (aActive !== bActive) return aActive - bActive
      return parseInt(b.dataset.locationCount) - parseInt(a.dataset.locationCount)
    })

    // Clear container and rebuild with proper order
    container.innerHTML = ''
    if (label) container.appendChild(label)
    buttons.forEach(button => container.appendChild(button))
    if (toggleButton) container.appendChild(toggleButton)
    if (removeButton) container.appendChild(removeButton)
  }

  filterPlants() {
    const showAllLocations = this.selectedLocations.size === 0
    const showAllRecipes = this.selectedRecipes.size === 0
    const showAllStatuses = this.selectedWateringStatuses.size === 0

    if (this.displayModeValue === "location") {
      this.locationGroupTargets.forEach(group => {
        const locationId = group.dataset.locationId
        const locationMatch = showAllLocations || this.selectedLocations.has(locationId)

        if (locationMatch) {
          const cards = group.querySelectorAll(".plant-card[data-recipe-id]")
          let visibleCount = 0

          cards.forEach(card => {
            const recipeId = card.dataset.recipeId
            const wateringStatus = card.dataset.wateringStatus
            const recipeMatch = showAllRecipes || this.selectedRecipes.has(recipeId)
            const statusMatch = showAllStatuses || this.selectedWateringStatuses.has(wateringStatus)
            const visible = recipeMatch && statusMatch
            card.style.display = visible ? "" : "none"
            if (visible) visibleCount++
          })

          group.style.display = visibleCount > 0 ? "" : "none"
        } else {
          group.style.display = "none"
        }
      })
    } else if (this.displayModeValue === "recipe") {
      this.recipeGroupTargets.forEach(group => {
        const recipeId = group.dataset.recipeId
        const recipeMatch = showAllRecipes || this.selectedRecipes.has(recipeId)

        if (recipeMatch) {
          const cards = group.querySelectorAll(".plant-card[data-location-id]")
          let visibleCount = 0

          cards.forEach(card => {
            const locationId = card.dataset.locationId
            const wateringStatus = card.dataset.wateringStatus
            const locationMatch = showAllLocations || this.selectedLocations.has(locationId)
            const statusMatch = showAllStatuses || this.selectedWateringStatuses.has(wateringStatus)
            const visible = locationMatch && statusMatch
            card.style.display = visible ? "" : "none"
            if (visible) visibleCount++
          })

          group.style.display = visibleCount > 0 ? "" : "none"
        } else {
          group.style.display = "none"
        }
      })
    } else {
      const cards = this.element.querySelectorAll(".plant-card[data-location-id]")
      cards.forEach(card => {
        const locationId = card.dataset.locationId
        const recipeId = card.dataset.recipeId
        const wateringStatus = card.dataset.wateringStatus
        const locationMatch = showAllLocations || this.selectedLocations.has(locationId)
        const recipeMatch = showAllRecipes || this.selectedRecipes.has(recipeId)
        const statusMatch = showAllStatuses || this.selectedWateringStatuses.has(wateringStatus)
        card.style.display = (locationMatch && recipeMatch && statusMatch) ? "" : "none"
      })
    }
  }

  updateResultsCount() {
    if (!this.hasWateringCountTarget || !this.hasTotalCountTarget) return
    const showAllLocations = this.selectedLocations.size === 0
    const showAllRecipes = this.selectedRecipes.size === 0
    const showAllStatuses = this.selectedWateringStatuses.size === 0

    // Only count cards in the currently visible display mode container
    let container
    if (this.displayModeValue === "location" && this.hasLocationGroupsContainerTarget) {
      container = this.locationGroupsContainerTarget
    } else if (this.displayModeValue === "recipe" && this.hasRecipeGroupsContainerTarget) {
      container = this.recipeGroupsContainerTarget
    } else if (this.hasWateringGroupsContainerTarget) {
      container = this.wateringGroupsContainerTarget
    } else {
      container = this.element
    }
    const cards = container.querySelectorAll(".plant-card[data-location-id]")

    let total = 0
    let needsWatering = 0

    cards.forEach(card => {
      const locationId = card.dataset.locationId
      const recipeId = card.dataset.recipeId
      const wateringStatus = card.dataset.wateringStatus
      const locationMatch = showAllLocations || this.selectedLocations.has(locationId)
      const recipeMatch = showAllRecipes || this.selectedRecipes.has(recipeId)
      const statusMatch = showAllStatuses || this.selectedWateringStatuses.has(wateringStatus)
      const visible = locationMatch && recipeMatch && statusMatch

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
    const hasActiveFilters = !showAllLocations || !showAllRecipes || !showAllStatuses

    if (hasActiveFilters && this.searchTermValue) {
      // Filters + search active
      totalText = this.resultsFilteredSearchTemplateValue
        .replace("__TOTAL__", total)
        .replace("__SEARCH_TERM__", this.searchTermValue)
    } else if (hasActiveFilters) {
      // Only filters active
      totalText = this.resultsFilteredTemplateValue
        .replace("__TOTAL__", total)
    } else if (this.searchTermValue) {
      // Only search active
      totalText = this.resultsSearchTemplateValue
        .replace("__TOTAL__", total)
        .replace("__SEARCH_TERM__", this.searchTermValue)
    } else {
      // No filters or search
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

    // Update group counts
    this.updateGroupCounts()
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

    // Get the label, toggle button, and remove button to preserve them at the end
    const label = container.querySelector('.display-toggle-label')
    const toggleButton = container.querySelector('.recipe-filters-toggle')
    const removeButton = container.querySelector('.remove-filter-btn')

    const buttons = this.recipeFilterButtonTargets.slice()

    buttons.sort((a, b) => {
      const aActive = this.selectedRecipes.has(a.dataset.recipeId) ? 0 : 1
      const bActive = this.selectedRecipes.has(b.dataset.recipeId) ? 0 : 1
      if (aActive !== bActive) return aActive - bActive
      return parseInt(b.dataset.recipeCount) - parseInt(a.dataset.recipeCount)
    })

    // Clear container and rebuild with proper order
    container.innerHTML = ''
    if (label) container.appendChild(label)
    buttons.forEach(button => container.appendChild(button))
    if (toggleButton) container.appendChild(toggleButton)
    if (removeButton) container.appendChild(removeButton)
  }

  // Display mode switching (client-side, preserves filters)
  switchDisplayMode(event) {
    const newMode = event.currentTarget.dataset.mode
    if (newMode === this.displayModeValue) return

    this.displayModeValue = newMode

    // Update URL without page reload
    const url = new URL(window.location.href)
    url.searchParams.set('display', newMode)
    window.history.pushState({}, '', url.toString())

    // Update button active states
    this.element.querySelectorAll('.display-toggle button[data-mode]').forEach(btn => {
      if (btn.dataset.mode === newMode) {
        btn.classList.add('active')
      } else {
        btn.classList.remove('active')
      }
    })

    this.updateDisplayMode()
  }

  updateDisplayMode() {
    // Show/hide appropriate containers based on display mode
    if (this.hasLocationGroupsContainerTarget) {
      this.locationGroupsContainerTarget.style.display = this.displayModeValue === "location" ? "" : "none"
    }

    if (this.hasRecipeGroupsContainerTarget) {
      this.recipeGroupsContainerTarget.style.display = this.displayModeValue === "recipe" ? "" : "none"
    }

    if (this.hasWateringGroupsContainerTarget) {
      this.wateringGroupsContainerTarget.style.display = this.displayModeValue === "watering" ? "" : "none"
    }

    // Re-apply filters after mode switch
    this.filterPlants()
    this.updateResultsCount()
  }

  // Watering status filtering
  toggleWateringStatusFilter(event) {
    const status = event.currentTarget.dataset.status
    if (this.selectedWateringStatuses.has(status)) {
      this.selectedWateringStatuses.delete(status)
    } else {
      this.selectedWateringStatuses.add(status)
    }
    this.applyWateringStatusFilter()
  }

  applyWateringStatusFilter() {
    this.updateWateringStatusButtonStates()
    this.filterPlants()
    this.updateResultsCount()
  }

  updateWateringStatusButtonStates() {
    if (!this.hasWateringStatusButtonTarget) return
    this.wateringStatusButtonTargets.forEach(button => {
      const status = button.dataset.status
      if (this.selectedWateringStatuses.has(status)) {
        button.classList.add("active")
      } else {
        button.classList.remove("active")
      }
    })
  }

  // Search clear button
  clearSearch(event) {
    event.preventDefault()
    if (this.hasSearchInputTarget) {
      this.searchInputTarget.value = ""
      this.updateSearchClearButton()
      // Trigger form submission to reload with empty search
      const form = this.searchInputTarget.closest('form')
      if (form) {
        form.requestSubmit()
      }
    } else {
      // Fallback to old method
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

  updateSearchClearButton() {
    if (!this.hasSearchInputTarget || !this.hasClearSearchBtnTarget) return
    const hasValue = this.searchInputTarget.value.trim().length > 0
    this.clearSearchBtnTarget.style.display = hasValue ? "" : "none"
  }

  // Update group counts for location and recipe groups
  updateGroupCounts() {
    if (!this.hasGroupCountTarget) return

    this.groupCountTargets.forEach(countTarget => {
      const group = countTarget.closest('[data-location-filter-target="locationGroup"], [data-location-filter-target="recipeGroup"]')
      if (!group) return

      const visibleCards = group.querySelectorAll('.plant-card[style*="display: none"]')
      const totalCards = group.querySelectorAll('.plant-card')
      const visibleCount = totalCards.length - visibleCards.length

      countTarget.textContent = visibleCount
    })
  }

  // Show/hide filter sections
  showStatusFilter() {
    if (this.hasWateringStatusContainerTarget) {
      this.wateringStatusContainerTarget.style.display = ""
    }
    if (this.hasAddStatusFilterBtnTarget) {
      this.addStatusFilterBtnTarget.style.display = "none"
    }
    this.updateAddFiltersVisibility()
  }

  hideStatusFilter() {
    // Clear active filters
    this.selectedWateringStatuses.clear()
    this.updateWateringStatusButtonStates()

    if (this.hasWateringStatusContainerTarget) {
      this.wateringStatusContainerTarget.style.display = "none"
    }
    if (this.hasAddStatusFilterBtnTarget) {
      this.addStatusFilterBtnTarget.style.display = ""
    }

    this.filterPlants()
    this.updateResultsCount()
    this.updateAddFiltersVisibility()
  }

  showRecipeFilter() {
    if (this.hasRecipeFilterContainerTarget) {
      this.recipeFilterContainerTarget.style.display = ""
    }
    if (this.hasAddRecipeFilterBtnTarget) {
      this.addRecipeFilterBtnTarget.style.display = "none"
    }
    this.updateAddFiltersVisibility()
  }

  hideRecipeFilter() {
    // Clear active filters
    this.selectedRecipes.clear()
    this.updateRecipeButtonStates()

    if (this.hasRecipeFilterContainerTarget) {
      this.recipeFilterContainerTarget.style.display = "none"
    }
    if (this.hasAddRecipeFilterBtnTarget) {
      this.addRecipeFilterBtnTarget.style.display = ""
    }

    this.filterPlants()
    this.updateResultsCount()
    this.updateAddFiltersVisibility()
  }

  showLocationFilter() {
    if (this.hasLocationFilterContainerTarget) {
      this.locationFilterContainerTarget.style.display = ""
    }
    if (this.hasAddLocationFilterBtnTarget) {
      this.addLocationFilterBtnTarget.style.display = "none"
    }
    this.updateAddFiltersVisibility()
  }

  hideLocationFilter() {
    // Clear active filters
    this.selectedLocations.clear()
    this.updateButtonStates()

    if (this.hasLocationFilterContainerTarget) {
      this.locationFilterContainerTarget.style.display = "none"
    }
    if (this.hasAddLocationFilterBtnTarget) {
      this.addLocationFilterBtnTarget.style.display = ""
    }

    this.filterPlants()
    this.updateResultsCount()
    this.updateAddFiltersVisibility()
  }

  // Update visibility of "Add filter:" container
  updateAddFiltersVisibility() {
    if (!this.hasAddFiltersContainerTarget) return

    // Check if all available filter sections are visible
    const allVisible = this.areAllFiltersVisible()

    // Hide "Add filter:" section if all filters are visible, show it otherwise
    this.addFiltersContainerTarget.style.display = allVisible ? "none" : ""
  }

  areAllFiltersVisible() {
    let allVisible = true

    // Check status filter
    if (this.hasWateringStatusContainerTarget) {
      const isVisible = this.wateringStatusContainerTarget.style.display !== "none"
      if (!isVisible) allVisible = false
    }

    // Check recipe filter
    if (this.hasRecipeFilterContainerTarget) {
      const isVisible = this.recipeFilterContainerTarget.style.display !== "none"
      if (!isVisible) allVisible = false
    }

    // Check location filter
    if (this.hasLocationFilterContainerTarget) {
      const isVisible = this.locationFilterContainerTarget.style.display !== "none"
      if (!isVisible) allVisible = false
    }

    return allVisible
  }
}
