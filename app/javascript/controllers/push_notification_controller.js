import { Controller } from "@hotwired/stimulus"
import { PushNotificationManager } from "push_notifications"

export default class extends Controller {
  static values = { vapidKey: String }
  static targets = ["status", "deviceList", "testPushWrap", "testPushHint"]

  async connect() {
    this.manager = new PushNotificationManager(this.vapidKeyValue)

    if (!await this.manager.isSupported()) {
      if (this.hasStatusTarget) this.statusTarget.textContent = "Push notifications are not supported in this browser."
      return
    }

    await this._updateUI()

    // Sync device states when the global push toggle changes
    this.element.addEventListener("notification-enabled", () => this._onGlobalEnabled())
    this.element.addEventListener("notification-disabled", () => this._onGlobalDisabled())
  }

  async subscribe() {
    try {
      await this.manager.subscribe()
      window.location.reload()
    } catch (error) {
      if (this.hasStatusTarget) {
        if (error.name === 'NotAllowedError') {
          this.statusTarget.textContent = "Notification permission was denied."
        } else {
          this.statusTarget.textContent = "Failed to subscribe to push notifications."
        }
      }
    }
  }

  async unsubscribe() {
    try {
      await this.manager.unsubscribe()
      window.location.reload()
    } catch (error) {
      if (this.hasStatusTarget) this.statusTarget.textContent = "Failed to unsubscribe."
    }
  }

  async toggleDevice(event) {
    const button = event.currentTarget
    const row = button.closest(".push-device")
    const subscriptionId = row.dataset.subscriptionId
    const wasEnabled = row.dataset.enabled === "true"

    // Optimistic UI update
    button.disabled = true
    const newEnabled = !wasEnabled

    try {
      const token = document.querySelector('meta[name="csrf-token"]')?.content
      const response = await fetch(`/push_subscriptions/${subscriptionId}/toggle`, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": token
        }
      })

      if (!response.ok) throw new Error("Toggle failed")

      // Update row state
      row.dataset.enabled = String(newEnabled)
      if (newEnabled) {
        row.classList.remove("push-device-disabled")
        button.textContent = "Disable"
        button.className = "push-device-remove"
      } else {
        row.classList.add("push-device-disabled")
        button.textContent = "Enable"
        button.className = "push-device-enable"
      }

      // Update date text
      const dateEl = row.querySelector(".push-device-date")
      if (dateEl) {
        dateEl.textContent = newEnabled ? "Enabled" : "Disabled"
      }

      // Show/hide Forget button (only visible when disabled, never for current device)
      const forgetWrap = row.querySelector(".push-device-forget-wrap")
      if (forgetWrap) {
        const isCurrentDevice = row.classList.contains("current-device")
        forgetWrap.style.display = (!newEnabled && !isCurrentDevice) ? "" : "none"
      }

      this._updateTestPushButton()
      this._syncHeaderToggle()
    } catch (error) {
      // Revert on failure — just reload
      window.location.reload()
    } finally {
      button.disabled = false
    }
  }

  async _updateUI() {
    const subscription = await this.manager.getExistingSubscription()

    if (subscription) {
      const currentRow = this._markCurrentDevice(subscription.endpoint)
      if (this.hasStatusTarget) {
        const isDisabled = currentRow && currentRow.dataset.enabled === "false"
        this.statusTarget.textContent = isDisabled
          ? "Push notifications are disabled for this device."
          : "Push notifications are enabled."
      }
    } else {
      if (this.hasStatusTarget) this.statusTarget.textContent = "Push notifications are disabled."
      this._injectDisabledCurrentDevice()
    }

    this._updateTestPushButton()
  }

  _markCurrentDevice(endpoint) {
    if (!this.hasDeviceListTarget) return null

    let foundRow = null
    this.deviceListTarget.querySelectorAll(".push-device").forEach(row => {
      if (row.dataset.endpoint === endpoint) {
        foundRow = row
        row.classList.add("current-device")

        // Add "This Device" badge
        const nameEl = row.querySelector(".push-device-name")
        if (nameEl) {
          const badge = document.createElement("span")
          badge.className = "push-device-badge"
          badge.textContent = "This Device"
          nameEl.after(badge)
        }
      }
    })

    // Browser has subscription but no server record — re-register
    if (!foundRow) {
      this._reRegisterSubscription()
    }

    return foundRow
  }

  async _reRegisterSubscription() {
    try {
      const subscription = await this.manager.getExistingSubscription()
      if (subscription) {
        await this.manager._sendSubscriptionToServer(subscription)
        window.location.reload()
      }
    } catch (error) {
      // Re-registration failed, show as unsubscribed
      this._injectCurrentDeviceRow(false)
    }
  }

  _injectDisabledCurrentDevice() {
    if (!this.hasDeviceListTarget) return
    this._injectCurrentDeviceRow(false)
  }

  _injectCurrentDeviceRow(subscribed) {
    const row = document.createElement("div")
    row.className = "push-device current-device"

    const info = document.createElement("div")
    info.className = "push-device-info"

    const name = document.createElement("span")
    name.className = "push-device-name"
    name.textContent = this._detectDeviceName()

    const badge = document.createElement("span")
    badge.className = "push-device-badge"
    badge.textContent = "This Device"

    const date = document.createElement("span")
    date.className = "push-device-date"
    date.textContent = subscribed ? "Subscribed" : "Not subscribed"

    info.appendChild(name)
    info.appendChild(badge)
    info.appendChild(date)

    const btn = document.createElement("button")
    btn.type = "button"
    if (subscribed) {
      btn.className = "push-device-remove"
      btn.textContent = "Disable"
      btn.addEventListener("click", () => this.unsubscribe())
    } else {
      btn.className = "push-device-enable"
      btn.textContent = "Enable"
      btn.addEventListener("click", () => this.subscribe())
    }

    row.appendChild(info)
    row.appendChild(btn)

    this.deviceListTarget.prepend(row)
  }

  _hasAnyEnabledDevice() {
    if (!this.hasDeviceListTarget) return false
    return this.deviceListTarget.querySelectorAll('.push-device[data-enabled="true"]').length > 0
  }

  _updateTestPushButton() {
    if (!this.hasTestPushWrapTarget) return
    const hasEnabled = this._hasAnyEnabledDevice()
    const btn = this.testPushWrapTarget.querySelector("button[type='submit']")
    if (btn) {
      btn.disabled = !hasEnabled
    }
    if (this.hasTestPushHintTarget) {
      this.testPushHintTarget.style.display = hasEnabled ? "none" : ""
    }
  }

  _syncHeaderToggle() {
    if (this._suppressHeaderSync) return

    // Find the parent notification-settings controller's toggle checkbox
    const card = this.element.closest(".notification-card")
    if (!card) return
    const toggle = card.querySelector('[data-notification-settings-target="toggle"]')
    if (!toggle) return

    const hasEnabled = this._hasAnyEnabledDevice()

    if (!hasEnabled && toggle.checked) {
      // All devices disabled — turn off the header toggle without collapsing
      toggle.checked = false
      // Update the hidden field too
      const hidden = card.querySelector('[data-notification-settings-target="hiddenEnabled"]')
      if (hidden) hidden.value = "false"
      // Persist to server
      this._updateHeaderToggleOnServer(card, false)
    } else if (hasEnabled && !toggle.checked) {
      // A device was enabled — turn on the header toggle without expanding (already expanded)
      toggle.checked = true
      const hidden = card.querySelector('[data-notification-settings-target="hiddenEnabled"]')
      if (hidden) hidden.value = "true"
      this._updateHeaderToggleOnServer(card, true)
    }
  }

  async _updateHeaderToggleOnServer(card, enabled) {
    const toggleUrl = card.dataset.notificationSettingsToggleUrlValue
    if (!toggleUrl) return
    const channel = card.dataset.notificationSettingsChannelValue
    const token = document.querySelector('meta[name="csrf-token"]')?.content
    await fetch(toggleUrl, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "X-CSRF-Token": token
      },
      body: `channel=${channel}`
    })
  }

  async _onGlobalEnabled() {
    if (this._hasAnyEnabledDevice()) return

    this._suppressHeaderSync = true

    const currentRow = this.hasDeviceListTarget
      ? this.deviceListTarget.querySelector(".push-device.current-device")
      : null

    if (!currentRow) {
      this._suppressHeaderSync = false
      return
    }

    if (currentRow.dataset.subscriptionId) {
      const toggleBtn = currentRow.querySelector('[data-action="click->push-notification#toggleDevice"]')
      if (toggleBtn) toggleBtn.click()
    } else {
      const btn = currentRow.querySelector("button")
      if (btn) btn.click()
    }

    this._suppressHeaderSync = false
  }

  async _onGlobalDisabled() {
    if (!this.hasDeviceListTarget) return

    // Suppress _syncHeaderToggle while we're bulk-disabling from the global toggle
    this._suppressHeaderSync = true

    // Disable all enabled devices
    const enabledRows = this.deviceListTarget.querySelectorAll('.push-device[data-enabled="true"]')
    for (const row of enabledRows) {
      const toggleBtn = row.querySelector('[data-action="click->push-notification#toggleDevice"]')
      if (toggleBtn) toggleBtn.click()
      // Wait briefly so each toggle completes before the next
      await new Promise(r => setTimeout(r, 100))
    }

    this._suppressHeaderSync = false
  }

  _detectDeviceName() {
    const ua = navigator.userAgent
    if (/iPhone|iPad|iPod/.test(ua)) return "iOS Device"
    if (/Android/.test(ua)) return "Android Device"
    if (/Mac/.test(ua)) return "Mac"
    if (/Windows/.test(ua)) return "Windows PC"
    if (/Linux/.test(ua)) return "Linux PC"
    return "This Browser"
  }
}
