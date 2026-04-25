import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "filterButton", "recipeFilterButton", "buttonContainer", "recipeButtonContainer",
    "locationGroup", "recipeGroup", "resultsCount", "wateringCount", "totalCount",
    "searchInput", "clearSearchBtn",
    "wateringGroup", "groupCount",
    "locationGroupsContainer", "recipeGroupsContainer", "wateringGroupsContainer",
    "paginationControls", "paginationNav", "paginationInfo",
    "saveSearchContainer", "filterParamsInput"
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
    showingTemplate: String,
    clearSearchLabel: { type: String, default: "Clear Search" }
  }

  connect() {
    this.selectedLocations = new Set()
    this.selectedRecipes = new Set()
    this.updateSearchClearButton()
    this.cleanUrl()
    this.initFromUrl()
    this.updateSaveFormVisibility()
    const filterParamsInput = this._crossTarget('filterParamsInput')
    if (filterParamsInput) filterParamsInput.value = window.location.search
    this.paginateVisibleCards()

    // Re-apply counts and pagination after Turbo Stream replaces a plant card
    document.addEventListener("turbo:before-stream-render", this._handleStreamRender = (event) => {
      const originalRender = event.detail.render
      event.detail.render = (streamElement) => {
        originalRender(streamElement)
        this.updateResultsCount()
        if (this.displayModeValue === "watering") {
          this.paginateVisibleCards()
        }
      }
    })

    // Inner controller: receive filter state dispatched by the outer (header) controller
    document.addEventListener('location-filter:apply', this._handleApply = (e) => {
      if (!this.hasWateringGroupsContainerTarget && !this.hasLocationGroupsContainerTarget) return
      this.selectedLocations = new Set(e.detail.locations)
      this.selectedRecipes = new Set(e.detail.recipes)
      if (e.detail.currentPage !== undefined) this.currentPageValue = e.detail.currentPage
      this.filterPlants()
      this.updateResultsCount()
      if (this.displayModeValue === "watering") this.paginateVisibleCards()
    })
  }

  disconnect() {
    if (this._handleStreamRender) {
      document.removeEventListener("turbo:before-stream-render", this._handleStreamRender)
    }
    if (this._handleApply) {
      document.removeEventListener('location-filter:apply', this._handleApply)
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
    this._dispatchApply()
    this.syncFiltersToUrl()
    this.updateSaveFormVisibility()
  }

  _dispatchApply() {
    document.dispatchEvent(new CustomEvent('location-filter:apply', {
      detail: {
        locations: [...this.selectedLocations],
        recipes: [...this.selectedRecipes],
        currentPage: this.currentPageValue
      }
    }))
  }

  updateButtonStates() {
    this._crossTargets('filterButton').forEach(button => {
      const locationId = button.dataset.locationId
      if (this.selectedLocations.has(locationId)) {
        button.classList.add("active")
      } else {
        button.classList.remove("active")
      }
    })
  }

  reorderButtons() {
    const container = this._crossTarget('buttonContainer')
    if (!container) return

    const buttons = this._crossTargets('filterButton').slice()

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

    if (this.displayModeValue === "location") {
      this.locationGroupTargets.forEach(group => {
        const locationId = group.dataset.locationId
        const locationMatch = showAllLocations || this.selectedLocations.has(locationId)

        if (locationMatch) {
          const cards = group.querySelectorAll(".plant-card[data-recipe-id]")
          let visibleCount = 0

          cards.forEach(card => {
            const recipeId = card.dataset.recipeId
            const recipeMatch = showAllRecipes || this.selectedRecipes.has(recipeId)
            card.removeAttribute("data-filter-hidden")
            card.style.display = recipeMatch ? "" : "none"
            if (!recipeMatch) card.setAttribute("data-filter-hidden", "true")
            if (recipeMatch) visibleCount++
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
            const locationMatch = showAllLocations || this.selectedLocations.has(locationId)
            card.removeAttribute("data-filter-hidden")
            card.style.display = locationMatch ? "" : "none"
            if (!locationMatch) card.setAttribute("data-filter-hidden", "true")
            if (locationMatch) visibleCount++
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
        const locationMatch = showAllLocations || this.selectedLocations.has(locationId)
        const recipeMatch = showAllRecipes || this.selectedRecipes.has(recipeId)
        card.removeAttribute("data-filter-hidden")
        if (!locationMatch || !recipeMatch) {
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
        const locationMatch = showAllLocations || this.selectedLocations.has(locationId)
        const recipeMatch = showAllRecipes || this.selectedRecipes.has(recipeId)
        visible = locationMatch && recipeMatch
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
    const hasActiveFilters = !showAllLocations || !showAllRecipes

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

    // Update the text content
    this.totalCountTarget.textContent = totalText

    // Show/hide "Clear Search" link based on any active state
    const shouldShowClear = hasActiveFilters || !!this.searchTermValue || this.displayModeValue !== "watering"
    const existingLink = this.totalCountTarget.querySelector("a")
    if (shouldShowClear && !existingLink) {
      const link = document.createElement("a")
      link.href = "#"
      link.textContent = this.clearSearchLabelValue
      link.dataset.action = "click->location-filter#clearSearch"
      this.totalCountTarget.appendChild(document.createTextNode(" - "))
      this.totalCountTarget.appendChild(link)
    } else if (!shouldShowClear && existingLink) {
      existingLink.previousSibling?.remove()
      existingLink.remove()
    }

    // Update group counts
    this.updateGroupCounts()
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
    this._dispatchApply()
    this.syncFiltersToUrl()
    this.updateSaveFormVisibility()
  }

  updateRecipeButtonStates() {
    this._crossTargets('recipeFilterButton').forEach(button => {
      const recipeId = button.dataset.recipeId
      if (this.selectedRecipes.has(recipeId)) {
        button.classList.add("active")
      } else {
        button.classList.remove("active")
      }
    })
  }

  reorderRecipeButtons() {
    const container = this._crossTarget('recipeButtonContainer')
    if (!container) return

    const buttons = this._crossTargets('recipeFilterButton').slice()

    buttons.sort((a, b) => {
      const aActive = this.selectedRecipes.has(a.dataset.recipeId) ? 0 : 1
      const bActive = this.selectedRecipes.has(b.dataset.recipeId) ? 0 : 1
      if (aActive !== bActive) return aActive - bActive
      return parseInt(b.dataset.recipeCount) - parseInt(a.dataset.recipeCount)
    })

    this.animateReorder(container, buttons)
  }

  // Returns target from this controller instance, falling back to a document-wide lookup.
  // Used for cross-instance communication between the outer (header) and inner (turbo-frame) controllers.
  _crossTarget(name) {
    const hasKey = `has${name[0].toUpperCase()}${name.slice(1)}Target`
    return this[hasKey] ? this[`${name}Target`] : document.querySelector(`[data-location-filter-target="${name}"]`)
  }

  _crossTargets(name) {
    const hasKey = `has${name[0].toUpperCase()}${name.slice(1)}Target`
    return this[hasKey] ? this[`${name}Targets`] : Array.from(document.querySelectorAll(`[data-location-filter-target="${name}"]`))
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
    this.updateSaveFormVisibility()
    if (this.hasFilterParamsInputTarget) this.filterParamsInputTarget.value = url.search
    this.updateSearchClearButton()
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

  clearSearch(event) {
    event.preventDefault()
    // Clear filter URL params so _injectFilterParams doesn't carry them forward
    const url = new URL(window.location.href)
    url.searchParams.delete("locations[]")
    url.searchParams.delete("recipes[]")
    url.searchParams.delete("hide_scheduled")
    window.history.replaceState({}, "", url.toString())

    this._resetInstantly()

    const form = this.hasSearchInputTarget
      ? this.searchInputTarget.closest("form")
      : document.querySelector('#headerSearch form')
    if (form) form.requestSubmit()
  }

  _resetInstantly() {
    // Clear filter selection state
    this.selectedLocations.clear()
    this.selectedRecipes.clear()

    // Deactivate all filter buttons (works across both controller instances)
    document.querySelectorAll('[data-location-filter-target="filterButton"]').forEach(b => b.classList.remove("active"))
    document.querySelectorAll('[data-location-filter-target="recipeFilterButton"]').forEach(b => b.classList.remove("active"))

    // Reset hide-scheduled switch
    this._syncHideScheduledSwitch(false)

    // Clear search input
    const searchInput = this.hasSearchInputTarget
      ? this.searchInputTarget
      : document.querySelector('[data-location-filter-target="searchInput"]')
    if (searchInput) searchInput.value = ""

    // Hide ✕ clear button
    const clearBtn = this.hasClearSearchBtnTarget
      ? this.clearSearchBtnTarget
      : document.querySelector('[data-location-filter-target="clearSearchBtn"]')
    if (clearBtn) clearBtn.style.display = "none"

    // Remove "Clear Search" text link
    const totalCount = this.hasTotalCountTarget
      ? this.totalCountTarget
      : document.querySelector('[data-location-filter-target="totalCount"]')
    if (totalCount) {
      const link = totalCount.querySelector("a")
      if (link) {
        if (link.previousSibling?.nodeType === Node.TEXT_NODE) link.previousSibling.remove()
        link.remove()
      }
    }

    // Mark frame as loading so CSS can show a loading indicator
    const frame = document.querySelector('turbo-frame#plants-results')
    if (frame) frame.setAttribute('aria-busy', 'true')
  }

  toggleHideScheduled(event) {
    const checkbox = event.currentTarget
    const isActive = checkbox.checked
    const label = checkbox.closest('.hide-scheduled-switch')?.querySelector('.hide-scheduled-label')
    if (label) {
      this._fadeLabel(label, isActive
        ? (checkbox.dataset.showWateredLabel || 'Watered Plants\nHidden')
        : (checkbox.dataset.hideWateredLabel || 'Showing\nWatered Plants'))
    }
    const form = checkbox.closest('form')
    if (form) form.requestSubmit()
  }

  _syncHideScheduledSwitch(isActive) {
    const checkbox = document.querySelector('input[name="hide_scheduled"]')
    if (!checkbox) return
    checkbox.checked = isActive
    const label = checkbox.closest('.hide-scheduled-switch')?.querySelector('.hide-scheduled-label')
    if (label) {
      label.textContent = isActive
        ? (checkbox.dataset.showWateredLabel || 'Watered Plants\nHidden')
        : (checkbox.dataset.hideWateredLabel || 'Showing\nWatered Plants')
    }
  }

  _fadeLabel(label, text) {
    label.classList.add('fading')
    requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        label.textContent = text
        label.classList.remove('fading')
      })
    })
  }

  loadSavedSearch(event) {
    const queryTerm = event.currentTarget.dataset.queryTerm || ""
    if (this.hasSearchInputTarget) {
      this.searchInputTarget.value = queryTerm
      this.updateSearchClearButton()
    } else {
      const searchInput = document.querySelector('[data-location-filter-target="searchInput"]')
      const clearBtn = document.querySelector('[data-location-filter-target="clearSearchBtn"]')
      if (searchInput) {
        searchInput.value = queryTerm
        if (clearBtn) clearBtn.style.display = queryTerm.length > 0 ? "" : "none"
      }
    }

    // Sync hide-scheduled switch from the saved search's URL
    const href = event.currentTarget.getAttribute('href') || ""
    const savedParams = new URLSearchParams(href.includes('?') ? href.split('?')[1] : '')
    this._syncHideScheduledSwitch(savedParams.get('hide_scheduled') === 'true')
  }

  updateSearchClearButton() {
    const clearBtn = this.hasClearSearchBtnTarget
      ? this.clearSearchBtnTarget
      : document.querySelector('[data-location-filter-target="clearSearchBtn"]')
    if (!clearBtn) return
    const searchInput = this.hasSearchInputTarget
      ? this.searchInputTarget
      : document.querySelector('[data-location-filter-target="searchInput"]')
    const hasText = (searchInput?.value?.trim()?.length ?? 0) > 0
    const params = new URLSearchParams(window.location.search)
    const hasFilters = params.has("locations[]") || params.has("recipes[]")
    const nonDefaultDisplay = params.get("display") && params.get("display") !== "watering"
    const hideScheduledActive = params.get("hide_scheduled") === "true"
    clearBtn.style.display = (hasText || hasFilters || nonDefaultDisplay || hideScheduledActive) ? "" : "none"
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

  clearLocationFilter() {
    this.selectedLocations.clear()
    this.updateButtonStates()
    this.currentPageValue = 1
    this._dispatchApply()
    this.syncFiltersToUrl()
    this.updateSaveFormVisibility()
  }

  clearRecipeFilter() {
    this.selectedRecipes.clear()
    this.updateRecipeButtonStates()
    this.currentPageValue = 1
    this._dispatchApply()
    this.syncFiltersToUrl()
    this.updateSaveFormVisibility()
  }

  updateSaveFormVisibility() {
    const saveSearchContainer = this._crossTarget('saveSearchContainer')
    if (!saveSearchContainer) return
    const hideScheduledActive = new URLSearchParams(window.location.search).get('hide_scheduled') === 'true'
    const hasActiveState =
      this.selectedLocations.size > 0 ||
      this.selectedRecipes.size > 0 ||
      this.displayModeValue !== "watering" ||
      this.searchTermValue.length > 0 ||
      hideScheduledActive
    saveSearchContainer.style.display = hasActiveState ? "" : "none"
  }

  cleanUrl() {
    const url = new URL(window.location.href)
    const key = "q[name_or_location_name_cont]"
    if (url.searchParams.has(key) && url.searchParams.get(key) === "") {
      url.searchParams.delete(key)
      window.history.replaceState({}, "", url.toString())
    }
  }

  initFromUrl() {
    const params = new URLSearchParams(window.location.search)
    const locationIds = params.getAll("locations[]")
    const recipeIds = params.getAll("recipes[]")

    if (locationIds.length === 0 && recipeIds.length === 0) return

    locationIds.forEach(id => this.selectedLocations.add(id))
    recipeIds.forEach(id => this.selectedRecipes.add(id))

    this.updateButtonStates()
    this.updateRecipeButtonStates()
    this.reorderButtons()
    this.reorderRecipeButtons()
    this.filterPlants()
    this.updateResultsCount()
    this.updateSaveFormVisibility()
    this.updateSearchClearButton()
  }

  syncFiltersToUrl() {
    const url = new URL(window.location.href)
    url.searchParams.delete("locations[]")
    url.searchParams.delete("recipes[]")
    this.selectedLocations.forEach(id => url.searchParams.append("locations[]", id))
    this.selectedRecipes.forEach(id => url.searchParams.append("recipes[]", id))
    window.history.replaceState({}, "", url.toString())
    const filterParamsInput = this._crossTarget('filterParamsInput')
    if (filterParamsInput) filterParamsInput.value = url.search
    this.updateSearchClearButton()
  }
}
