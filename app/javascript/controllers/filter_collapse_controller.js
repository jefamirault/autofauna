import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["filterRow", "toggleBtn"]

  connect() {
    this._collapsed = false
    this._suppressAutoCollapse = false

    const main = document.querySelector('main')
    if (main) {
      this._main = main
      this._onScroll = this._handleScroll.bind(this)
      main.addEventListener('scroll', this._onScroll, { passive: true })
    }
  }

  disconnect() {
    if (this._main && this._onScroll) {
      this._main.removeEventListener('scroll', this._onScroll)
    }
  }

  toggle() {
    if (this._collapsed) {
      this._suppressAutoCollapse = true
      this._expand()
      if (this._main) {
        this._main.scrollTo({ top: 0, behavior: 'smooth' })
      }
    } else {
      this._collapse()
    }
  }

  _handleScroll() {
    if (this._suppressAutoCollapse) {
      if (this._main.scrollTop <= 10) this._suppressAutoCollapse = false
      return
    }
    const scrolled = this._main.scrollTop > 10
    if (scrolled && !this._collapsed) {
      this._collapse()
    } else if (!scrolled && this._collapsed) {
      this._expand()
    }
  }

  _collapse() {
    if (this._collapsed || !this.hasFilterRowTarget) return
    this._collapsed = true
    const row = this.filterRowTarget
    row.style.height = row.offsetHeight + 'px'
    row.offsetHeight // force reflow
    row.style.height = '0'
    this._updateToggleBtn()
  }

  _expand() {
    if (!this._collapsed || !this.hasFilterRowTarget) return
    this._collapsed = false
    const row = this.filterRowTarget
    const targetHeight = row.scrollHeight
    row.style.height = targetHeight + 'px'
    row.addEventListener('transitionend', () => {
      if (!this._collapsed) row.style.height = 'auto'
    }, { once: true })
    this._updateToggleBtn()
  }

  _updateToggleBtn() {
    if (!this.hasToggleBtnTarget) return
    this.toggleBtnTarget.setAttribute('aria-expanded', String(!this._collapsed))
  }
}
