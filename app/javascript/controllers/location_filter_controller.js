import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "filterButton", "recipeFilterButton", "buttonContainer", "recipeButtonContainer",
    "locationGroup", "recipeGroup", "resultsCount", "wateringCount", "totalCount",
    "searchInput", "clearSearchBtn", "wateringStatusButton", "wateringStatusContainer",
    "wateringGroup", "groupCount",
    "addStatusFilterBtn", "addRecipeFilterBtn", "addLocationFilterBtn",
    "locationFilterContainer", "recipeFilterContainer", "addFiltersContainer", "filterRow",
    "locationGroupsContainer", "recipeGroupsContainer", "wateringGroupsContainer",
    "paginationControls", "paginationNav", "paginationInfo"
  ]
  static values = {
    displayMode: String,
    wateringTemplate: String,
    resultsTemplate: String,
    resultsSearchTemplate: String,
    resultsFilteredTemplate: String,
    resultsFilteredSearchTemplate: String,
    searchTerm: String,
    perPage: { type: Number, default: 20 },
    currentPage: { type: Number, default: 1 },
    showingTemplate: String
  }

  connect() {
    this.selectedLocations = new Set()
    this.selectedRecipes = new Set()
    this.selectedWateringStatuses = new Set()
    this.updateSearchClearButton()
    this.updateAddFiltersVisibility()
    this.paginateVisibleCards()

    // Observe status filter scroll container for overflow
    if (this.hasWateringStatusContainerTarget) {
      const scrollEl = this.wateringStatusContainerTarget.querySelector('.filter-buttons-scroll')
      if (scrollEl) {
        this.statusResizeObserver = new ResizeObserver(() => this.checkStatusOverflow())
        this.statusResizeObserver.observe(scrollEl)
      }
    }

    // Re-apply counts and pagination after Turbo Stream replaces a plant card
    document.addEventListener("turbo:after-stream-render", this._handleStreamRender = () => {
      this.updateResultsCount()
      if (this.displayModeValue === "watering") {
        this.paginateVisibleCards()
      }
    })
  }

  disconnect() {
    if (this.statusResizeObserver) {
      this.statusResizeObserver.disconnect()
    }
    if (this._handleStreamRender) {
      document.removeEventListener("turbo:after-stream-render", this._handleStreamRender)
    }
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
    this.currentPageValue = 1
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

    this.animateReorder(container, buttons)
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
            card.removeAttribute("data-filter-hidden")
            card.style.display = visible ? "" : "none"
            if (!visible) card.setAttribute("data-filter-hidden", "true")
            if (visible) visibleCount++
          })

          group.style.display = visibleCount > 0 ? "" : "none"
        } else {
          group.style.display = "none"
          group.querySelectorAll(".plant-card").forEach(card => {
            card.setAttribute("data-filter-hidden", "true")
            card.style.display = "none"
          })
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
            card.removeAttribute("data-filter-hidden")
            card.style.display = visible ? "" : "none"
            if (!visible) card.setAttribute("data-filter-hidden", "true")
            if (visible) visibleCount++
          })

          group.style.display = visibleCount > 0 ? "" : "none"
        } else {
          group.style.display = "none"
          group.querySelectorAll(".plant-card").forEach(card => {
            card.setAttribute("data-filter-hidden", "true")
            card.style.display = "none"
          })
        }
      })
    } else {
      // Watering mode - use data-filter-hidden, then paginate
      const cards = this.element.querySelectorAll('[data-location-filter-target="wateringGroup"] .plant-card[data-location-id]')
      cards.forEach(card => {
        const locationId = card.dataset.locationId
        const recipeId = card.dataset.recipeId
        const wateringStatus = card.dataset.wateringStatus
        const locationMatch = showAllLocations || this.selectedLocations.has(locationId)
        const recipeMatch = showAllRecipes || this.selectedRecipes.has(recipeId)
        const statusMatch = showAllStatuses || this.selectedWateringStatuses.has(wateringStatus)
        const visible = locationMatch && recipeMatch && statusMatch
        card.removeAttribute("data-filter-hidden")
        if (!visible) {
          card.setAttribute("data-filter-hidden", "true")
        }
      })
      this.paginateVisibleCards()
    }
  }

  paginateVisibleCards() {
    if (this.displayModeValue !== "watering") return
    if (!this.hasWateringGroupsContainerTarget) return

    const allCards = Array.from(
      this.wateringGroupsContainerTarget.querySelectorAll('.plant-card[data-location-id]')
    )

    // Collect cards not hidden by filters
    const visibleCards = allCards.filter(card => !card.hasAttribute("data-filter-hidden"))
    const total = visibleCards.length
    const perPage = this.perPageValue

    // If perPage is 0 (All), show everything
    if (perPage === 0) {
      visibleCards.forEach(card => card.style.display = "")
      allCards.filter(card => card.hasAttribute("data-filter-hidden")).forEach(card => card.style.display = "none")
      this.renderPaginationControls(total, total, 0)
      return
    }

    const totalPages = Math.max(1, Math.ceil(total / perPage))
    if (this.currentPageValue > totalPages) this.currentPageValue = totalPages

    const start = (this.currentPageValue - 1) * perPage
    const end = Math.min(start + perPage, total)

    visibleCards.forEach((card, index) => {
      if (index >= start && index < end) {
        card.style.display = ""
      } else {
        card.style.display = "none"
      }
    })

    // Ensure filter-hidden cards stay hidden
    allCards.filter(card => card.hasAttribute("data-filter-hidden")).forEach(card => card.style.display = "none")

    this.renderPaginationControls(total, totalPages, start)
  }

  renderPaginationControls(total, totalPages, start) {
    if (!this.hasPaginationNavTarget || !this.hasPaginationInfoTarget) return

    const perPage = this.perPageValue
    const currentPage = this.currentPageValue

    // Info text
    if (perPage === 0 || total === 0) {
      this.paginationInfoTarget.textContent = ""
    } else {
      const from = total === 0 ? 0 : start + 1
      const to = Math.min(start + perPage, total)
      if (this.hasShowingTemplateValue && this.showingTemplateValue) {
        this.paginationInfoTarget.textContent = this.showingTemplateValue
          .replace("__FROM__", from)
          .replace("__TO__", to)
          .replace("__TOTAL__", total)
      } else {
        this.paginationInfoTarget.textContent = `${from}-${to} of ${total}`
      }
    }

    // Nav buttons
    this.paginationNavTarget.innerHTML = ""

    if (perPage === 0 || totalPages <= 1) return

    // Prev button
    const prevBtn = document.createElement("button")
    prevBtn.textContent = "‹"
    prevBtn.disabled = currentPage <= 1
    prevBtn.addEventListener("click", () => this.goToPage(currentPage - 1))
    this.paginationNavTarget.appendChild(prevBtn)

    // Page buttons - show up to 5 pages around current
    const maxButtons = 5
    let startPage = Math.max(1, currentPage - Math.floor(maxButtons / 2))
    let endPage = Math.min(totalPages, startPage + maxButtons - 1)
    if (endPage - startPage < maxButtons - 1) {
      startPage = Math.max(1, endPage - maxButtons + 1)
    }

    if (startPage > 1) {
      this.paginationNavTarget.appendChild(this.createPageButton(1, currentPage))
      if (startPage > 2) {
        const dots = document.createElement("span")
        dots.textContent = "…"
        dots.style.padding = "0 0.25rem"
        this.paginationNavTarget.appendChild(dots)
      }
    }

    for (let i = startPage; i <= endPage; i++) {
      this.paginationNavTarget.appendChild(this.createPageButton(i, currentPage))
    }

    if (endPage < totalPages) {
      if (endPage < totalPages - 1) {
        const dots = document.createElement("span")
        dots.textContent = "…"
        dots.style.padding = "0 0.25rem"
        this.paginationNavTarget.appendChild(dots)
      }
      this.paginationNavTarget.appendChild(this.createPageButton(totalPages, currentPage))
    }

    // Next button
    const nextBtn = document.createElement("button")
    nextBtn.textContent = "›"
    nextBtn.disabled = currentPage >= totalPages
    nextBtn.addEventListener("click", () => this.goToPage(currentPage + 1))
    this.paginationNavTarget.appendChild(nextBtn)
  }

  createPageButton(page, currentPage) {
    const btn = document.createElement("button")
    btn.textContent = page
    if (page === currentPage) btn.classList.add("active")
    btn.addEventListener("click", () => this.goToPage(page))
    return btn
  }

  goToPage(page) {
    this.currentPageValue = page
    this.paginateVisibleCards()
  }

  changePerPage(event) {
    this.perPageValue = parseInt(event.target.value)
    this.currentPageValue = 1
    this.paginateVisibleCards()
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
      // In watering mode, use data-filter-hidden; in other modes, check filter match
      let visible
      if (this.displayModeValue === "watering") {
        visible = !card.hasAttribute("data-filter-hidden")
      } else {
        const locationId = card.dataset.locationId
        const recipeId = card.dataset.recipeId
        const wateringStatus = card.dataset.wateringStatus
        const locationMatch = showAllLocations || this.selectedLocations.has(locationId)
        const recipeMatch = showAllRecipes || this.selectedRecipes.has(recipeId)
        const statusMatch = showAllStatuses || this.selectedWateringStatuses.has(wateringStatus)
        visible = locationMatch && recipeMatch && statusMatch
      }

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
    this.currentPageValue = 1
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

    this.animateReorder(container, buttons)
  }

  animateAddFilter(addBtn, filterContainer) {
    if (!addBtn || !filterContainer) {
      if (filterContainer) filterContainer.style.display = ""
      if (addBtn) addBtn.style.display = "none"
      return
    }

    // Capture the add-filter button's position
    const startRect = addBtn.getBoundingClientRect()

    // Hide add button, show filter container and filter row
    addBtn.style.display = "none"
    filterContainer.style.display = ""
    if (this.hasFilterRowTarget) {
      this.filterRowTarget.style.display = ""
    }

    // Find the filter-section-label in the new container
    const label = filterContainer.querySelector('.filter-section-label')
    if (!label) return

    const endRect = label.getBoundingClientRect()
    const dx = startRect.left - endRect.left
    const dy = startRect.top - endRect.top

    if (dx === 0 && dy === 0) return

    label.style.transition = 'none'
    label.style.transform = `translate(${dx}px, ${dy}px)`
    label.offsetHeight // force reflow
    label.style.transition = 'transform 0.12s ease'
    label.style.transform = ''
    label.addEventListener('transitionend', () => {
      label.style.transition = ''
    }, { once: true })
  }

  animateRemoveFilter(addBtn, filterContainer) {
    if (!addBtn || !filterContainer) {
      if (filterContainer) filterContainer.style.display = "none"
      if (addBtn) addBtn.style.display = ""
      return
    }

    // Capture the filter-section-label's position before hiding
    const label = filterContainer.querySelector('.filter-section-label')
    if (!label) {
      filterContainer.style.display = "none"
      addBtn.style.display = ""
      return
    }

    const startRect = label.getBoundingClientRect()

    // Hide filter container, show add button and add-filters row
    filterContainer.style.display = "none"
    addBtn.style.display = ""
    if (this.hasAddFiltersContainerTarget) {
      this.addFiltersContainerTarget.style.display = ""
    }

    const endRect = addBtn.getBoundingClientRect()
    const dx = startRect.left - endRect.left
    const dy = startRect.top - endRect.top

    if (dx === 0 && dy === 0) return

    addBtn.style.transition = 'none'
    addBtn.style.transform = `translate(${dx}px, ${dy}px)`
    addBtn.offsetHeight // force reflow
    addBtn.style.transition = 'transform 0.12s ease'
    addBtn.style.transform = ''
    addBtn.addEventListener('transitionend', () => {
      addBtn.style.transition = ''
    }, { once: true })
  }

  animateReorder(container, sortedButtons) {
    // FLIP: capture initial positions
    const firstPositions = new Map()
    sortedButtons.forEach(btn => {
      firstPositions.set(btn, btn.getBoundingClientRect())
    })

    // Move buttons to sorted order (preserve .filter-actions at end)
    const actions = container.querySelector('.filter-actions')
    sortedButtons.forEach(btn => container.insertBefore(btn, actions))

    // FLIP: capture final positions and animate
    sortedButtons.forEach(btn => {
      const first = firstPositions.get(btn)
      const last = btn.getBoundingClientRect()
      const dx = first.left - last.left
      const dy = first.top - last.top

      if (dx === 0 && dy === 0) return

      btn.style.transition = 'none'
      btn.style.transform = `translate(${dx}px, ${dy}px)`
      btn.offsetHeight // force reflow
      btn.style.transition = 'transform 0.12s ease'
      btn.style.transform = ''
      btn.addEventListener('transitionend', () => {
        btn.style.transition = ''
      }, { once: true })
    })
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
    this.element.querySelectorAll('.sort-row button[data-mode]').forEach(btn => {
      if (btn.dataset.mode === newMode) {
        btn.classList.add('active')
      } else {
        btn.classList.remove('active')
      }
    })

    this.currentPageValue = 1
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

    // Show/hide pagination (only in watering mode)
    if (this.hasPaginationControlsTarget) {
      this.paginationControlsTarget.style.display = this.displayModeValue === "watering" ? "" : "none"
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
    this.currentPageValue = 1
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
    const addBtn = this.hasAddStatusFilterBtnTarget ? this.addStatusFilterBtnTarget : null
    const container = this.hasWateringStatusContainerTarget ? this.wateringStatusContainerTarget : null

    this.animateAddFilter(addBtn, container)

    if (container) this.checkStatusOverflow()
    this.updateAddFiltersVisibility()
  }

  hideStatusFilter() {
    // Clear active filters
    this.selectedWateringStatuses.clear()
    this.updateWateringStatusButtonStates()

    const addBtn = this.hasAddStatusFilterBtnTarget ? this.addStatusFilterBtnTarget : null
    const container = this.hasWateringStatusContainerTarget ? this.wateringStatusContainerTarget : null
    this.animateRemoveFilter(addBtn, container)

    this.currentPageValue = 1
    this.filterPlants()
    this.updateResultsCount()
    this.updateAddFiltersVisibility()
  }

  showRecipeFilter() {
    const addBtn = this.hasAddRecipeFilterBtnTarget ? this.addRecipeFilterBtnTarget : null
    const container = this.hasRecipeFilterContainerTarget ? this.recipeFilterContainerTarget : null

    this.animateAddFilter(addBtn, container)
    this.updateAddFiltersVisibility()
  }

  hideRecipeFilter() {
    // Clear active filters
    this.selectedRecipes.clear()
    this.updateRecipeButtonStates()

    const addBtn = this.hasAddRecipeFilterBtnTarget ? this.addRecipeFilterBtnTarget : null
    const container = this.hasRecipeFilterContainerTarget ? this.recipeFilterContainerTarget : null
    this.animateRemoveFilter(addBtn, container)

    this.currentPageValue = 1
    this.filterPlants()
    this.updateResultsCount()
    this.updateAddFiltersVisibility()
  }

  showLocationFilter() {
    const addBtn = this.hasAddLocationFilterBtnTarget ? this.addLocationFilterBtnTarget : null
    const container = this.hasLocationFilterContainerTarget ? this.locationFilterContainerTarget : null

    this.animateAddFilter(addBtn, container)
    this.updateAddFiltersVisibility()
  }

  hideLocationFilter() {
    // Clear active filters
    this.selectedLocations.clear()
    this.updateButtonStates()

    const addBtn = this.hasAddLocationFilterBtnTarget ? this.addLocationFilterBtnTarget : null
    const container = this.hasLocationFilterContainerTarget ? this.locationFilterContainerTarget : null
    this.animateRemoveFilter(addBtn, container)

    this.currentPageValue = 1
    this.filterPlants()
    this.updateResultsCount()
    this.updateAddFiltersVisibility()
  }

  // Update visibility of "Add filter:" container and filter row
  updateAddFiltersVisibility() {
    if (!this.hasAddFiltersContainerTarget) return

    // Check if all available filter sections are visible
    const allVisible = this.areAllFiltersVisible()
    const anyVisible = this.areAnyFiltersVisible()

    // Hide "Add filter:" section if all filters are visible, show it otherwise
    this.addFiltersContainerTarget.style.display = allVisible ? "none" : ""

    // Show filter row only when at least one filter section is active
    if (this.hasFilterRowTarget) {
      this.filterRowTarget.style.display = anyVisible ? "" : "none"
    }
  }

  checkStatusOverflow() {
    if (!this.hasWateringStatusContainerTarget) return
    const el = this.wateringStatusContainerTarget.querySelector('.filter-buttons-scroll')
    if (!el) return
    const overflowing = el.scrollWidth > el.clientWidth
    el.classList.toggle("is-overflowing", overflowing)
  }

  areAnyFiltersVisible() {
    if (this.hasWateringStatusContainerTarget && this.wateringStatusContainerTarget.style.display !== "none") return true
    if (this.hasRecipeFilterContainerTarget && this.recipeFilterContainerTarget.style.display !== "none") return true
    if (this.hasLocationFilterContainerTarget && this.locationFilterContainerTarget.style.display !== "none") return true
    return false
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
