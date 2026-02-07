import { Controller } from "@hotwired/stimulus"
import { PushNotificationManager } from "push_notifications"

export default class extends Controller {
  static values = { vapidKey: String }
  static targets = ["subscribeButton", "unsubscribeButton", "status"]

  async connect() {
    this.manager = new PushNotificationManager(this.vapidKeyValue)

    if (!await this.manager.isSupported()) {
      this.statusTarget.textContent = "Push notifications are not supported in this browser."
      this.subscribeButtonTarget.style.display = "none"
      this.unsubscribeButtonTarget.style.display = "none"
      return
    }

    await this._updateUI()
  }

  async subscribe() {
    try {
      await this.manager.subscribe()
      await this._updateUI()
    } catch (error) {
      if (error.name === 'NotAllowedError') {
        this.statusTarget.textContent = "Notification permission was denied."
      } else {
        this.statusTarget.textContent = "Failed to subscribe to push notifications."
      }
    }
  }

  async unsubscribe() {
    try {
      await this.manager.unsubscribe()
      await this._updateUI()
    } catch (error) {
      this.statusTarget.textContent = "Failed to unsubscribe."
    }
  }

  async _updateUI() {
    const subscription = await this.manager.getExistingSubscription()
    if (subscription) {
      this.subscribeButtonTarget.style.display = "none"
      this.unsubscribeButtonTarget.style.display = ""
      this.statusTarget.textContent = "Push notifications are enabled."
    } else {
      this.subscribeButtonTarget.style.display = ""
      this.unsubscribeButtonTarget.style.display = "none"
      this.statusTarget.textContent = "Push notifications are disabled."
    }
  }
}
