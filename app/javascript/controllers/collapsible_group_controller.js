import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["header", "content", "icon"]
  static values = { storageKey: String }

  connect() {
    const saved = localStorage.getItem(this.storageKeyValue)
    if (saved === "collapsed") {
      this.collapse()
    }
  }

  toggle() {
    if (this.contentTarget.style.display === "none") {
      this.expand()
    } else {
      this.collapse()
    }
  }

  collapse() {
    this.contentTarget.style.display = "none"
    this.iconTarget.textContent = "▶"
    localStorage.setItem(this.storageKeyValue, "collapsed")
  }

  expand() {
    this.contentTarget.style.display = ""
    this.iconTarget.textContent = "▼"
    localStorage.setItem(this.storageKeyValue, "expanded")
  }
}
