export class PushNotificationManager {
  constructor(vapidPublicKey) {
    this.vapidPublicKey = vapidPublicKey
  }

  async isSupported() {
    return 'serviceWorker' in navigator && 'PushManager' in window
  }

  async getExistingSubscription() {
    const registration = await navigator.serviceWorker.ready
    return registration.pushManager.getSubscription()
  }

  async subscribe() {
    // First, request notification permission from the browser
    const permission = await Notification.requestPermission()

    // If user denies permission, throw a clear error
    if (permission !== 'granted') {
      throw new Error('Notification permission denied')
    }

    // Now that we have permission, proceed with push subscription
    const registration = await navigator.serviceWorker.ready
    const subscription = await registration.pushManager.subscribe({
      userVisibleOnly: true,
      applicationServerKey: this._urlBase64ToUint8Array(this.vapidPublicKey)
    })

    await this._sendSubscriptionToServer(subscription)
    return subscription
  }

  async unsubscribe() {
    const subscription = await this.getExistingSubscription()
    if (subscription) {
      await this._removeSubscriptionFromServer(subscription)
      await subscription.unsubscribe()
    }
  }

  async _sendSubscriptionToServer(subscription) {
    const key = subscription.getKey('p256dh')
    const auth = subscription.getKey('auth')

    const response = await fetch('/push_subscriptions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({
        endpoint: subscription.endpoint,
        p256dh_key: btoa(String.fromCharCode.apply(null, new Uint8Array(key))),
        auth_key: btoa(String.fromCharCode.apply(null, new Uint8Array(auth)))
      })
    })

    if (!response.ok) {
      throw new Error('Failed to save push subscription')
    }
  }

  async _removeSubscriptionFromServer(subscription) {
    await fetch('/push_subscriptions/' + encodeURIComponent(subscription.endpoint), {
      method: 'DELETE',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({ endpoint: subscription.endpoint })
    })
  }

  _urlBase64ToUint8Array(base64String) {
    const padding = '='.repeat((4 - base64String.length % 4) % 4)
    const base64 = (base64String + padding).replace(/-/g, '+').replace(/_/g, '/')
    const rawData = atob(base64)
    const outputArray = new Uint8Array(rawData.length)
    for (let i = 0; i < rawData.length; ++i) {
      outputArray[i] = rawData.charCodeAt(i)
    }
    return outputArray
  }
}
