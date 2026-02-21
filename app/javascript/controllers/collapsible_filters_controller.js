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

    this.resizeObserver = new ResizeObserver(() => this.checkOverflow())
    this.resizeObserver.observe(this.containerTarget)

    this.narrowMQ = window.matchMedia('(max-width: 500px)')
    this.narrowMQ.addEventListener('change', this._onNarrowChange = () => this.updateUI())
  }

  disconnect() {
    if (this.resizeObserver) {
      this.resizeObserver.disconnect()
    }
    if (this.narrowMQ) {
      this.narrowMQ.removeEventListener('change', this._onNarrowChange)
    }
  }

  toggle() {
    this.expandedValue = !this.expandedValue
    localStorage.setItem("location-filters-expanded", this.expandedValue)
    this.updateUI()
  }

  get isNarrow() {
    return window.matchMedia('(max-width: 500px)').matches
  }

  updateUI() {
    const narrow = this.isNarrow
    if (this.expandedValue) {
      this.containerTarget.classList.add("expanded")
      this.toggleButtonTarget.textContent = narrow
        ? this.toggleButtonTarget.dataset.lessTextShort
        : this.toggleButtonTarget.dataset.lessText
    } else {
      this.containerTarget.classList.remove("expanded")
      this.toggleButtonTarget.textContent = narrow
        ? this.toggleButtonTarget.dataset.moreTextShort
        : this.toggleButtonTarget.dataset.moreText
      this.containerTarget.scrollLeft = 0
    }
    this.checkOverflow()
  }

  checkOverflow() {
    const el = this.containerTarget
    const overflowing = el.scrollWidth > el.clientWidth
    el.classList.toggle("is-overflowing", overflowing)

    // Hide "show more" when collapsed and not overflowing (all buttons already visible)
    if (this.hasToggleButtonTarget) {
      this.toggleButtonTarget.style.display = (!this.expandedValue && !overflowing) ? "none" : ""
    }
  }
}
