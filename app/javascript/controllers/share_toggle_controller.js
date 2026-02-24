import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { key: String }
  static targets = ["body"]

  connect() {
    const body = this.bodyTarget
    body.style.overflow = "hidden"
    body.style.transition = "height 0.12s ease"

    const wasExpanded = localStorage.getItem(this._storageKey()) === "true"
    if (wasExpanded) {
      body.style.height = "auto"
    } else {
      body.style.height = "0"
    }

    this._observer = new MutationObserver(() => this._onContentChange())
    this._observer.observe(body, { childList: true, subtree: true })
  }

  disconnect() {
    if (this._observer) {
      this._observer.disconnect()
      this._observer = null
    }
  }

  toggle() {
    const expanding = this._isCollapsed()
    expanding ? this._expand() : this._collapse()
    localStorage.setItem(this._storageKey(), expanding)
  }

  _isCollapsed() {
    return this.bodyTarget.style.height === "0px" || this.bodyTarget.style.height === "0"
  }

  _expand() {
    const body = this.bodyTarget
    if (this._expandHandler) body.removeEventListener("transitionend", this._expandHandler)
    this._expandHandler = () => {
      body.style.height = "auto"
      this._expandHandler = null
    }
    body.style.height = body.scrollHeight + "px"
    body.addEventListener("transitionend", this._expandHandler, { once: true })
  }

  _collapse() {
    const body = this.bodyTarget
    if (this._expandHandler) {
      body.removeEventListener("transitionend", this._expandHandler)
      this._expandHandler = null
    }
    body.style.height = body.scrollHeight + "px"
    body.offsetHeight
    body.style.height = "0"
  }

  _onContentChange() {
    const body = this.bodyTarget
    if (!this._isCollapsed() && body.style.height !== "auto") {
      body.style.height = body.scrollHeight + "px"
    }
    if (body.style.height === "auto") {
      // Re-set to auto so scrollHeight recalculates on next toggle
    }
  }

  _storageKey() {
    return `share-toggle-${this.keyValue}`
  }
}
