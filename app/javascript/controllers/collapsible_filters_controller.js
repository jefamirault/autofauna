import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "toggleButton"]
  static values = { expanded: Boolean }

  connect() {
    const savedState = localStorage.getItem("location-filters-expanded")
    if (savedState === "true") {
      this.expandedValue = true
    }
    this.updateUI()
  }

  toggle() {
    this.expandedValue = !this.expandedValue
    localStorage.setItem("location-filters-expanded", this.expandedValue)
    this.updateUI()
  }

  updateUI() {
    if (this.expandedValue) {
      this.containerTarget.classList.add("expanded")
      this.toggleButtonTarget.textContent = this.toggleButtonTarget.dataset.lessText
    } else {
      this.containerTarget.classList.remove("expanded")
      this.toggleButtonTarget.textContent = this.toggleButtonTarget.dataset.moreText
    }
  }
}
