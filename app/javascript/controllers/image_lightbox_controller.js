import { Controller } from "@hotwired/stimulus"

// Click the plant image to view it fullscreen over a dimmed backdrop. The image
// animates from its thumbnail position into the centered fullscreen view (a FLIP
// shared-element transition) and back again on close. A single click/tap anywhere
// (or Escape) closes it.
export default class extends Controller {
  static values = { src: String }

  open(event) {
    event.preventDefault()
    if (this.overlay) return

    const thumb = event.currentTarget
    const overlay = document.createElement("div")
    overlay.className = "image-lightbox-overlay"

    const fullImg = document.createElement("img")
    fullImg.className = "image-lightbox-image"
    // Use the already-loaded thumbnail src first so the element has correct
    // dimensions immediately for the FLIP measurement; upgrade to hi-res after.
    fullImg.src = thumb.currentSrc || thumb.src
    fullImg.alt = thumb.alt || ""
    overlay.appendChild(fullImg)

    document.body.appendChild(overlay)
    document.body.classList.add("image-lightbox-open")

    // Hide the source so it reads as the element itself moving.
    thumb.style.visibility = "hidden"
    this.thumb = thumb
    this.fullImg = fullImg
    this.overlay = overlay

    if (this.animates) {
      // FLIP: start transformed onto the thumbnail's rect, then animate to identity.
      this._applyTransformFrom(thumb.getBoundingClientRect())
      void fullImg.offsetWidth // force reflow so the next change transitions
      fullImg.style.transition = `transform ${this.duration}ms ease`
      fullImg.style.transform = ""
    }
    overlay.classList.add("visible")

    // Upgrade to the hi-res variant (same aspect ratio → no layout jump).
    if (this.srcValue) fullImg.src = this.srcValue

    overlay.addEventListener("click", this.boundClose)
    overlay.addEventListener("wheel", this.boundWheel, { passive: true })
    overlay.addEventListener("touchstart", this.boundTouchStart, { passive: true })
    overlay.addEventListener("touchmove", this.boundTouchMove, { passive: true })
    document.addEventListener("keydown", this.boundKeydown)
  }

  close() {
    if (!this.overlay || this.closing) return
    this.closing = true
    document.removeEventListener("keydown", this.boundKeydown)
    this.overlay.classList.remove("visible")

    if (this.animates && this.thumb && this.fullImg) {
      // Reverse FLIP: animate from the centered rect back onto the thumbnail.
      this.fullImg.style.transition = `transform ${this.duration}ms ease`
      this._applyTransformFrom(this.thumb.getBoundingClientRect())
      this.fullImg.addEventListener("transitionend", this.boundTeardown, { once: true })
      this.closeTimer = setTimeout(this.boundTeardown, this.duration + 80)
    } else {
      this.boundTeardown()
    }
  }

  // Position/scale the fullscreen image so its box coincides with `rect`
  // (transform-origin: top left). Clearing the transform animates it home.
  _applyTransformFrom(rect) {
    const now = this.fullImg.getBoundingClientRect()
    if (!now.width || !now.height) return // not measurable yet — skip the FLIP, just fade
    const tx = rect.left - now.left
    const ty = rect.top - now.top
    const sx = rect.width / now.width
    const sy = rect.height / now.height
    this.fullImg.style.transformOrigin = "top left"
    this.fullImg.style.transform = `translate(${tx}px, ${ty}px) scale(${sx}, ${sy})`
  }

  keydown(event) {
    if (event.key === "Escape") this.close()
  }

  // Stable references so add/removeEventListener pair up and timers/transitionend share one handler.
  boundClose = () => this.close()
  // Only a downward scroll dismisses — scrolling up is what opened the view
  // (via dynamic_header_controller), so it must not immediately close it.
  boundWheel = (event) => { if (event.deltaY > 0) this.close() }
  boundKeydown = (event) => this.keydown(event)
  boundTeardown = () => this._teardown()

  // Swipe-to-dismiss: any drag past the threshold closes (in any direction).
  boundTouchStart = (event) => {
    const touch = event.changedTouches[0]
    this.touchStart = { x: touch.clientX, y: touch.clientY }
  }
  boundTouchMove = (event) => {
    if (!this.touchStart) return
    const touch = event.changedTouches[0]
    const dy = touch.clientY - this.touchStart.y
    // Only a deliberate upward swipe dismisses. Swiping down / scrolling up
    // (the same direction that opened it) and small moves do nothing.
    if (dy < -90) this.close()
  }

  _teardown() {
    if (this.closeTimer) { clearTimeout(this.closeTimer); this.closeTimer = null }
    if (this.thumb) { this.thumb.style.visibility = ""; this.thumb = null }
    if (this.overlay) { this.overlay.remove(); this.overlay = null }
    this.fullImg = null
    this.touchStart = null
    this.closing = false
    document.body.classList.remove("image-lightbox-open")
  }

  get duration() {
    return 300
  }

  get animates() {
    return !window.matchMedia("(prefers-reduced-motion: reduce)").matches
  }

  disconnect() {
    this._teardown()
  }
}
