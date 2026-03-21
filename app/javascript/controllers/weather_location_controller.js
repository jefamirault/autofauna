import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["detectButton", "status"]
  static values = { createUrl: String }

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
        this.saveLocation(lat, lon)
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

  saveLocation(lat, lon) {
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    const form = document.createElement("form")
    form.method = "post"
    form.action = this.createUrlValue

    const fields = {
      "authenticity_token": csrfToken,
      "weather_location[latitude]": lat,
      "weather_location[longitude]": lon,
      "weather_location[location_name]": "My Location"
    }

    for (const [name, value] of Object.entries(fields)) {
      const input = document.createElement("input")
      input.type = "hidden"
      input.name = name
      input.value = value
      form.appendChild(input)
    }

    document.body.appendChild(form)
    form.submit()
  }

  showStatus(message) {
    this.statusTarget.textContent = message
    this.statusTarget.style.display = "block"
  }
}
