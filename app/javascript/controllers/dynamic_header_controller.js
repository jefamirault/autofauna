import { Controller } from "@hotwired/stimulus"

// Continuously interpolates the header between expanded and collapsed states.
//
// Phase 1 (collapse): Intercepts wheel/touch events and prevents actual scrolling.
// Only the header shrinks — content stays visually in place.
//
// Phase 2 (normal): Header fully collapsed, normal scrolling resumes.
//
// When the user scrolls back up to scrollTop=0 and keeps going, the header
// re-expands (Phase 1 in reverse) before content can scroll further.
export default class extends Controller {
  connect() {
    this._readDimensions()

    // Only activate on pages with the expandable plant graphic header.
    // Other pages (e.g. plants index) have header_extra for the search bar
    // but no --header-expanded/--header-collapsed CSS variables.
    if (!this._scrollRange || isNaN(this._scrollRange) || this._scrollRange <= 0) return

    this._active = true
    this._delta = 0 // accumulated collapse progress in px
    this._overscroll = 0 // accumulated up-scroll past full expansion (opens fullscreen)

    this._wheelHandler = this._onWheel.bind(this)
    this._touchStartHandler = this._onTouchStart.bind(this)
    this._touchMoveHandler = this._onTouchMove.bind(this)
    this._touchEndHandler = this._onTouchEnd.bind(this)

    this.element.addEventListener("wheel", this._wheelHandler, { passive: false })
    this.element.addEventListener("touchstart", this._touchStartHandler, { passive: true })
    this.element.addEventListener("touchmove", this._touchMoveHandler, { passive: false })
    this.element.addEventListener("touchend", this._touchEndHandler, { passive: true })

    // The header is a separate grid area, not inside the scrolling <main>, so
    // wheel/touch over it never reaches <main>. Listen there too and forward
    // the gesture (collapse the header, then scroll the content) — see the
    // currentTarget === this._header forwarding in the handlers.
    this._header = document.querySelector("header")
    if (this._header) {
      this._header.addEventListener("wheel", this._wheelHandler, { passive: false })
      this._header.addEventListener("touchstart", this._touchStartHandler, { passive: true })
      this._header.addEventListener("touchmove", this._touchMoveHandler, { passive: false })
      this._header.addEventListener("touchend", this._touchEndHandler, { passive: true })
    }

    this._update()
  }

  disconnect() {
    if (!this._active) return
    this._cancelMomentum()
    this.element.removeEventListener("wheel", this._wheelHandler)
    this.element.removeEventListener("touchstart", this._touchStartHandler)
    this.element.removeEventListener("touchmove", this._touchMoveHandler)
    this.element.removeEventListener("touchend", this._touchEndHandler)
    if (this._header) {
      this._header.removeEventListener("wheel", this._wheelHandler)
      this._header.removeEventListener("touchstart", this._touchStartHandler)
      this._header.removeEventListener("touchmove", this._touchMoveHandler)
      this._header.removeEventListener("touchend", this._touchEndHandler)
    }
    if (this._clickSuppressor) {
      document.removeEventListener("click", this._clickSuppressor, true)
      clearTimeout(this._clickSuppressorTimer)
      this._clickSuppressor = null
    }
    document.body.style.removeProperty("--header-height")
    document.body.style.removeProperty("--graphic-opacity")
    document.body.style.removeProperty("--title-opacity")
  }

  _readDimensions() {
    const style = getComputedStyle(document.body)
    const rem = parseFloat(getComputedStyle(document.documentElement).fontSize)
    const expanded = parseFloat(style.getPropertyValue("--header-expanded")) * rem
    const collapsed = parseFloat(style.getPropertyValue("--header-collapsed")) * rem
    this._expandedPx = expanded
    this._collapsedPx = collapsed
    this._scrollRange = expanded - collapsed
  }

  _shouldCollapse() {
    // Once collapse has started, always allow it to finish.
    // Otherwise, only start collapsing if content overflows <main>.
    if (this._delta > 0) return true
    return this.element.scrollHeight > this.element.clientHeight
  }

  _onWheel(e) {
    if (e.deltaY > 0 && this._delta < this._scrollRange && this._shouldCollapse()) {
      // Scrolling down while header not fully collapsed — absorb into collapse
      e.preventDefault()
      this._delta = Math.min(this._scrollRange, this._delta + e.deltaY)
      this._update()
      this._overscroll = 0
    } else if (e.deltaY < 0 && this._delta > 0 && this.element.scrollTop <= 0) {
      // Scrolling up at top of content — expand header
      e.preventDefault()
      this._delta = Math.max(0, this._delta + e.deltaY)
      this._update()
      this._overscroll = 0
    } else if (e.deltaY < 0 && this._delta <= 0 && this.element.scrollTop <= 0) {
      // Fully expanded and still scrolling up at the top — open the fullscreen image
      e.preventDefault()
      this._accumulateOverscroll(-e.deltaY, false)
    } else if (e.deltaY > 0) {
      this._overscroll = 0
    }

    // Gesture over the header (outside <main>): if the collapse logic didn't
    // absorb it, forward the scroll to the content so it still moves.
    if (!e.defaultPrevented && e.currentTarget === this._header) {
      this.element.scrollTop += e.deltaY
      e.preventDefault()
    }
  }

  _onTouchStart(e) {
    this._cancelMomentum()
    this._overscroll = 0
    this._openedLightboxThisGesture = false
    if (e.touches.length === 1) {
      this._touchY = e.touches[0].clientY
      this._touchVelocity = 0
      this._lastTouchTime = e.timeStamp
    }
  }

  _onTouchMove(e) {
    if (e.touches.length !== 1 || this._touchY == null) return
    const currentY = e.touches[0].clientY
    const deltaY = this._touchY - currentY // positive = scrolling down
    this._touchY = currentY

    // Track velocity (px/ms) for momentum calculation
    const now = e.timeStamp
    const dt = now - (this._lastTouchTime || now)
    if (dt > 0) this._touchVelocity = deltaY / dt
    this._lastTouchTime = now

    if (deltaY > 0 && this._delta < this._scrollRange && this._shouldCollapse()) {
      e.preventDefault()
      this._delta = Math.min(this._scrollRange, this._delta + deltaY)
      this._update()
      this._overscroll = 0
    } else if (deltaY < 0 && this._delta > 0 && this.element.scrollTop <= 0) {
      e.preventDefault()
      this._delta = Math.max(0, this._delta + deltaY)
      this._update()
      this._overscroll = 0
    } else if (deltaY < 0 && this._delta <= 0 && this.element.scrollTop <= 0) {
      // Fully expanded and still pulling down at the top — open the fullscreen image
      this._accumulateOverscroll(-deltaY, true)
    } else if (deltaY > 0) {
      this._overscroll = 0
    }

    // Swipe over the header (outside <main>): if the collapse logic didn't
    // absorb it, forward the scroll to the content so it still moves.
    if (!e.defaultPrevented && e.currentTarget === this._header) {
      this.element.scrollTop += deltaY
      e.preventDefault()
    }
  }

  _onTouchEnd(_e) {
    // If this gesture opened the fullscreen view, swallow the trailing click the
    // finger-lift is about to fire (it would otherwise instantly close it).
    if (this._openedLightboxThisGesture) {
      this._openedLightboxThisGesture = false
      this._suppressNextClick()
    }

    // If the header is mid-transition, use touch velocity to animate to completion
    if (this._delta <= 0 || this._delta >= this._scrollRange) return
    if (!this._touchVelocity) return

    const velocity = this._touchVelocity // px/ms
    const FRICTION = 0.95
    const MIN_VELOCITY = 0.01 // px/ms threshold to stop

    let v = velocity
    let lastTime = null

    const step = (timestamp) => {
      if (lastTime === null) { lastTime = timestamp; this._momentumRaf = requestAnimationFrame(step); return }
      const dt = timestamp - lastTime
      lastTime = timestamp

      v *= Math.pow(FRICTION, dt / 16) // normalize friction to ~60fps
      if (Math.abs(v) < MIN_VELOCITY) { this._momentumRaf = null; return }

      const px = v * dt

      if (v > 0 && this._delta < this._scrollRange) {
        // Collapsing
        this._delta = Math.min(this._scrollRange, this._delta + px)
        this._update()
        if (this._delta < this._scrollRange) {
          this._momentumRaf = requestAnimationFrame(step)
        } else {
          this._momentumRaf = null
        }
      } else if (v < 0 && this._delta > 0 && this.element.scrollTop <= 0) {
        // Expanding
        this._delta = Math.max(0, this._delta + px)
        this._update()
        if (this._delta > 0) {
          this._momentumRaf = requestAnimationFrame(step)
        } else {
          this._momentumRaf = null
        }
      } else {
        this._momentumRaf = null
      }
    }

    this._momentumRaf = requestAnimationFrame(step)
  }

  _cancelMomentum() {
    if (this._momentumRaf) {
      cancelAnimationFrame(this._momentumRaf)
      this._momentumRaf = null
    }
  }

  // Once the header is fully expanded, continued up-scrolling at the top
  // accumulates here; past the threshold it opens the fullscreen image view.
  _accumulateOverscroll(px, isTouch) {
    if (px <= 0) return
    this._overscroll += px
    if (this._overscroll >= this._overscrollThreshold) {
      this._overscroll = 0
      this._openLightbox(isTouch)
    }
  }

  get _overscrollThreshold() {
    return 90 // px of up-scroll past full expansion before opening fullscreen
  }

  _openLightbox(isTouch) {
    const img = document.querySelector(".header-plant-graphic .plant-graphic-image")
    if (!img) return
    img.click() // triggers image-lightbox#open via its click action
    // When the open came from a touch pull, the finger-lift will fire a trailing
    // click on the freshly-added overlay that would instantly close it. Remember
    // to swallow that one click when this gesture ends (see _onTouchEnd).
    if (isTouch) this._openedLightboxThisGesture = true
  }

  // Capture and discard exactly the next click (the synthetic one from the
  // finger-lift that opened the lightbox), so it can't immediately dismiss it.
  _suppressNextClick() {
    if (this._clickSuppressor) return
    const cleanup = () => {
      document.removeEventListener("click", this._clickSuppressor, true)
      clearTimeout(this._clickSuppressorTimer)
      this._clickSuppressor = null
    }
    this._clickSuppressor = (e) => { e.stopPropagation(); cleanup() }
    document.addEventListener("click", this._clickSuppressor, true)
    this._clickSuppressorTimer = setTimeout(cleanup, 500)
  }

  _update() {
    const progress = this._delta / this._scrollRange
    const height = this._expandedPx - (progress * this._scrollRange)
    document.body.style.setProperty("--header-height", height + "px")
    document.body.style.setProperty("--graphic-opacity", 1 - progress)
    document.body.style.setProperty("--title-opacity", progress)
  }
}
