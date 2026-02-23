import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { channel: String, enabled: Boolean, toggleUrl: String }
  static targets = [
    "toggle", "body", "hiddenEnabled",
    "frequencyType", "frequencyToggle", "dailyBtn", "hourlyBtn",
    "dailyValueWrap", "dailyValue",
    "hourlyValueWrap", "hourlyValue",
    "dailyAtLabel", "hourlyStartLabel",
    "submitWrap", "submitButton",
    "testButton", "toggleLabel"
  ]

  connect() {
    const body = this.bodyTarget
    body.style.overflow = "hidden"
    body.style.transition = "height 0.12s ease"

    // Restore expanded state from localStorage (default to collapsed)
    const wasExpanded = localStorage.getItem(this._storageKey()) === "true"
    if (wasExpanded && this.enabledValue) {
      body.style.height = "auto"
    } else {
      body.style.height = "0"
    }

    // Collapse save button initially
    if (this.hasSubmitWrapTarget) {
      const wrap = this.submitWrapTarget
      wrap.style.overflow = "hidden"
      wrap.style.transition = "height 0.12s ease"
      wrap.style.height = "0"
    }

    // Snapshot initial form values for dirty tracking
    this._snapshotInitialValues()

    // Set initial toggle label and test button state
    this._updateToggleLabel()
    this._updateTestButton()
  }

  toggleExpand() {
    const expanding = this._isCollapsed()
    expanding ? this._expand() : this._collapse()
    localStorage.setItem(this._storageKey(), expanding)
  }

  preventPropagation(event) {
    event.stopPropagation()
  }

  toggleFromWrap(event) {
    // Don't double-toggle if the click was directly on the checkbox or its label
    if (event.target.closest(".switch")) return
    this.toggleTarget.checked = !this.toggleTarget.checked
    this.toggleTarget.dispatchEvent(new Event("change"))
  }

  async toggleEnabled() {
    const enabled = this.toggleTarget.checked
    this.enabledValue = enabled

    if (this.hasHiddenEnabledTarget) {
      this.hiddenEnabledTarget.value = enabled
    }

    localStorage.setItem(this._storageKey(), enabled)

    this._updateToggleLabel()
    this._updateTestButton()

    enabled ? this._expand() : this._collapse()

    // Notify child push-notification controller of global toggle change (after collapse)
    const pushController = this.bodyTarget.querySelector('[data-controller="push-notification"]')
    if (pushController) {
      const eventName = enabled ? "notification-enabled" : "notification-disabled"
      pushController.dispatchEvent(new CustomEvent(eventName))
    }

    const token = document.querySelector('meta[name="csrf-token"]')?.content
    await fetch(this.toggleUrlValue, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "X-CSRF-Token": token
      },
      body: `channel=${this.channelValue}`
    })
  }

  setDaily() {
    this.frequencyTypeTarget.value = "days"
    this.dailyBtnTarget.classList.add("active")
    this.hourlyBtnTarget.classList.remove("active")
    this._updateFrequencyDisplay()
    this._checkDirty()
  }

  setHourly() {
    this.frequencyTypeTarget.value = "hourly"
    this.hourlyBtnTarget.classList.add("active")
    this.dailyBtnTarget.classList.remove("active")
    this._updateFrequencyDisplay()
    this._checkDirty()
  }

  inputChanged() {
    this._checkDirty()
  }

  async handleSubmit(event) {
    event.preventDefault()
    const form = event.target
    const btn = this.hasSubmitButtonTarget ? this.submitButtonTarget : null

    // Disable and show "Saved!"
    if (btn) {
      btn.disabled = true
      btn.value = "Saved!"
    }

    // Submit via fetch
    const formData = new FormData(form)
    const token = document.querySelector('meta[name="csrf-token"]')?.content
    await fetch(form.action, {
      method: "PATCH",
      headers: { "X-CSRF-Token": token },
      body: formData,
      redirect: "manual"
    })

    // Update snapshot so _checkDirty sees clean state
    this._snapshotInitialValues()

    this._saving = true

    // Linger briefly so user sees "Saved!", then collapse
    if (this.hasSubmitWrapTarget) {
      const wrap = this.submitWrapTarget
      await new Promise(r => setTimeout(r, 1000))
      wrap.style.height = wrap.scrollHeight + "px"
      wrap.offsetHeight
      wrap.style.height = "0"
      wrap.addEventListener("transitionend", () => {
        this._saving = false
        if (btn) {
          btn.value = "Save"
          btn.disabled = false
        }
      }, { once: true })
    }
  }

  _updateToggleLabel() {
    if (!this.hasToggleLabelTarget) return
    this.toggleLabelTarget.textContent = this.toggleTarget.checked ? "ON" : "OFF"
  }

  _updateTestButton() {
    if (!this.hasTestButtonTarget) return
    const enabled = this.toggleTarget.checked
    const btn = this.testButtonTarget.querySelector("button[type='submit']")
    if (btn) btn.disabled = !enabled
  }

  _snapshotInitialValues() {
    this._initialValues = {}
    if (this.hasFrequencyTypeTarget) {
      this._initialValues.frequencyType = this.frequencyTypeTarget.value
    }
    if (this.hasDailyValueTarget) {
      this._initialValues.dailyValue = this.dailyValueTarget.value
    }
    if (this.hasHourlyValueTarget) {
      this._initialValues.hourlyValue = this.hourlyValueTarget.value
    }
    const timeInput = this.element.querySelector('input[type="time"]')
    if (timeInput) {
      this._initialValues.time = timeInput.value
    }
  }

  _isDirty() {
    if (this.hasFrequencyTypeTarget && this.frequencyTypeTarget.value !== this._initialValues.frequencyType) {
      return true
    }
    // Check the active value input based on current mode
    const isHourly = this.hasFrequencyTypeTarget && this.frequencyTypeTarget.value === "hourly"
    if (isHourly) {
      if (this.hasHourlyValueTarget && this.hourlyValueTarget.value !== this._initialValues.hourlyValue) {
        return true
      }
    } else {
      if (this.hasDailyValueTarget && this.dailyValueTarget.value !== this._initialValues.dailyValue) {
        return true
      }
    }
    const timeInput = this.element.querySelector('input[type="time"]')
    if (timeInput && timeInput.value !== this._initialValues.time) {
      return true
    }
    return false
  }

  _checkDirty() {
    if (!this.hasSubmitWrapTarget || this._saving) return
    this._isDirty() ? this._expandSubmit() : this._collapseSubmit()
  }

  _isSubmitCollapsed() {
    if (!this.hasSubmitWrapTarget) return true
    const h = this.submitWrapTarget.style.height
    return h === "0" || h === "0px"
  }

  _expandSubmit() {
    if (!this._isSubmitCollapsed()) return
    const wrap = this.submitWrapTarget
    wrap.style.height = wrap.scrollHeight + "px"
    wrap.addEventListener("transitionend", () => {
      wrap.style.height = "auto"
    }, { once: true })
  }

  _collapseSubmit() {
    if (this._isSubmitCollapsed()) return
    const wrap = this.submitWrapTarget

    // Force an explicit pixel height so the transition can animate to 0
    wrap.style.height = wrap.scrollHeight + "px"
    wrap.offsetHeight
    wrap.style.height = "0"

    // Reset button text and state after collapse finishes
    wrap.addEventListener("transitionend", () => {
      if (this.hasSubmitButtonTarget) {
        this.submitButtonTarget.value = "Save"
        this.submitButtonTarget.disabled = false
      }
    }, { once: true })
  }

  _isCollapsed() {
    return this.bodyTarget.style.height === "0px" || this.bodyTarget.style.height === "0"
  }

  _expand() {
    const body = this.bodyTarget
    // Cancel any pending collapse transitionend that would set height to "auto"
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
    // Cancel any pending expand transitionend that would reset height to "auto"
    if (this._expandHandler) {
      body.removeEventListener("transitionend", this._expandHandler)
      this._expandHandler = null
    }
    body.style.height = body.scrollHeight + "px"
    // Force reflow so the browser registers the explicit height before transitioning to 0
    body.offsetHeight
    body.style.height = "0"
  }

  _storageKey() {
    return `notification-settings-expanded-${this.channelValue}`
  }

  _updateFrequencyDisplay() {
    const isHourly = this.frequencyTypeTarget.value === "hourly"

    if (this.hasDailyValueWrapTarget) {
      this.dailyValueWrapTarget.style.display = isHourly ? "none" : ""
    }
    if (this.hasDailyValueTarget) {
      this.dailyValueTarget.disabled = isHourly
    }
    if (this.hasHourlyValueWrapTarget) {
      this.hourlyValueWrapTarget.style.display = isHourly ? "" : "none"
    }
    if (this.hasHourlyValueTarget) {
      this.hourlyValueTarget.disabled = !isHourly
    }
    if (this.hasDailyAtLabelTarget) {
      this.dailyAtLabelTarget.style.display = isHourly ? "none" : ""
    }
    if (this.hasHourlyStartLabelTarget) {
      this.hourlyStartLabelTarget.style.display = isHourly ? "" : "none"
    }
  }
}
