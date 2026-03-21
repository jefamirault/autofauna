import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["detectButton", "status"]

  detectLocation() {
    if (!navigator.geolocation) {
      this.showStatus("Geolocation is not supported by your browser.")
      return
    }

    this.detectButtonTarget.disabled = true
    this.detectButtonTarget.textContent = "Detecting..."
    this.showStatus("Requesting location access...")

    navigator.geolocation.getCurrentPosition(
      (position) => {
        const lat = position.coords.latitude.toFixed(4)
        const lon = position.coords.longitude.toFixed(4)
        window.location.href = `/weather?lat=${lat}&lon=${lon}`
      },
      (error) => {
        this.detectButtonTarget.disabled = false
        this.detectButtonTarget.textContent = "Use My Location"
        switch (error.code) {
          case error.PERMISSION_DENIED:
            this.showStatus("Location access denied. Please enter a zip code instead.")
            break
          case error.POSITION_UNAVAILABLE:
            this.showStatus("Location unavailable. Please enter a zip code instead.")
            break
          case error.TIMEOUT:
            this.showStatus("Location request timed out. Please try again.")
            break
          default:
            this.showStatus("Could not detect location. Please enter a zip code instead.")
        }
      },
      { timeout: 10000, enableHighAccuracy: false }
    )
  }

  showStatus(message) {
    this.statusTarget.textContent = message
    this.statusTarget.style.display = "block"
  }
}
