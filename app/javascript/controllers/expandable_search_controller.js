import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Check if search has a value on page load
    const hasValue = this.element.dataset.expandableSearchHasValue === "true"

    // Expand if there's a search value (mobile only - CSS handles desktop)
    if (hasValue && this.isMobile()) {
      this.expand()
    }

    // Listen for clicks outside to collapse
    this.handleClickOutside = this.handleClickOutside.bind(this)
    document.addEventListener('click', this.handleClickOutside)

    // Listen for Escape key to collapse
    this.handleEscape = this.handleEscape.bind(this)
    document.addEventListener('keydown', this.handleEscape)
  }

  disconnect() {
    document.removeEventListener('click', this.handleClickOutside)
    document.removeEventListener('keydown', this.handleEscape)
  }

  toggle(event) {
    event.stopPropagation()

    if (this.element.classList.contains('search-expanded')) {
      this.collapse()
    } else {
      this.expand()
    }
  }

  expand() {
    if (!this.isMobile()) return // Only expand/collapse on mobile

    this.element.classList.add('search-expanded')

    // Hide the logo text on mobile
    const logoText = document.querySelector('#logoText')
    if (logoText) {
      logoText.classList.add('hidden')
    }

    // Focus the input
    const input = this.element.querySelector('input[type="search"]')
    if (input) {
      setTimeout(() => input.focus(), 100)
    }
  }

  collapse() {
    if (!this.isMobile()) return // Only expand/collapse on mobile

    this.element.classList.remove('search-expanded')

    // Show the logo text on mobile
    const logoText = document.querySelector('#logoText')
    if (logoText) {
      logoText.classList.remove('hidden')
    }
  }

  handleClickOutside(event) {
    if (!this.isMobile()) return // Only handle on mobile
    if (!this.element.classList.contains('search-expanded')) return

    // Check if click is outside the search area
    if (!this.element.contains(event.target)) {
      this.collapse()
    }
  }

  handleEscape(event) {
    if (!this.isMobile()) return // Only handle on mobile
    if (!this.element.classList.contains('search-expanded')) return

    if (event.key === 'Escape') {
      this.collapse()
    }
  }

  isMobile() {
    return window.innerWidth <= 600
  }
}
