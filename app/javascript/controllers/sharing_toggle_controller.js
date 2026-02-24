import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "cards"]
  static values = { plantId: Number }

  get storageKey() {
    return `sharing-enabled-${this.plantIdValue}`
  }

  connect() {
    const cards = this.cardsTarget
    cards.style.transition = "height 0.12s ease, opacity 0.12s ease, margin-top 0.12s ease, padding-top 0.12s ease"
    cards.style.overflow = "hidden"

    const savedOpen = localStorage.getItem(this.storageKey) === "true"
    const serverOpen = cards.style.display !== "none"

    if (savedOpen && !serverOpen) {
      // localStorage says open, but server rendered collapsed
      cards.style.display = ""
      this.buttonTarget.textContent = "🔓 Sharing Enabled"
      this.buttonTarget.style.opacity = "1"
      this.buttonTarget.classList.add("sharing-active")
    } else if (!savedOpen && !serverOpen) {
      // Collapsed
      cards.style.display = ""
      cards.style.height = "0"
      cards.style.opacity = "0"
      cards.style.marginTop = "0"
      cards.style.paddingTop = "0"
    }

    this.buttonTarget.addEventListener("mouseenter", () => {
      if (!this.buttonTarget.classList.contains("sharing-active")) {
        this.buttonTarget.style.opacity = "1"
      }
    })
    this.buttonTarget.addEventListener("mouseleave", () => {
      if (!this.buttonTarget.classList.contains("sharing-active")) {
        this.buttonTarget.style.opacity = "0.7"
      }
    })
  }

  toggle(event) {
    event.preventDefault()
    const cards = this.cardsTarget
    const collapsed = cards.style.height === "0px" || cards.style.height === "0"

    if (collapsed) {
      cards.style.height = cards.scrollHeight + "px"
      cards.style.opacity = "1"
      cards.style.marginTop = ""
      cards.style.paddingTop = ""
      this.buttonTarget.textContent = "🔓 Sharing Enabled"
      this.buttonTarget.style.opacity = "1"
      this.buttonTarget.classList.add("sharing-active")
      localStorage.setItem(this.storageKey, "true")
      cards.addEventListener("transitionend", () => {
        cards.style.height = "auto"
      }, { once: true })
    } else {
      cards.style.height = cards.scrollHeight + "px"
      requestAnimationFrame(() => {
        requestAnimationFrame(() => {
          cards.style.height = "0"
          cards.style.opacity = "0"
          cards.style.marginTop = "0"
          cards.style.paddingTop = "0"
        })
      })
      this.buttonTarget.textContent = "🔒 Sharing Disabled"
      this.buttonTarget.style.opacity = "0.7"
      this.buttonTarget.classList.remove("sharing-active")
      localStorage.removeItem(this.storageKey)
    }
  }
}
