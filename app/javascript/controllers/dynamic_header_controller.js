import { Controller } from "@hotwired/stimulus"

// Watches scroll on <main> and collapses the expanded plant-graphic header
// when the user scrolls down. Restores the expanded header when scrolled back to top.
export default class extends Controller {
  static values = { threshold: { type: Number, default: 30 } }

  connect() {
    this.scrollHandler = this.onScroll.bind(this)
    this.element.addEventListener("scroll", this.scrollHandler, { passive: true })
  }

  disconnect() {
    this.element.removeEventListener("scroll", this.scrollHandler)
    document.body.classList.remove("header-collapsed")
  }

  onScroll() {
    const scrolled = this.element.scrollTop > this.thresholdValue
    document.body.classList.toggle("header-collapsed", scrolled)
  }
}
