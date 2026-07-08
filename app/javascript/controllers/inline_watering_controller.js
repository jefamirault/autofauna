import { Controller } from "@hotwired/stimulus"

// Guards the quick-water button on plant cards against double-submission
// while the Turbo Stream request is in flight.
export default class extends Controller {
  static targets = ["quickWaterBtn"]

  submitStart(event) {
    if (this.hasQuickWaterBtnTarget) {
      this.quickWaterBtnTarget.disabled = true
      this.quickWaterBtnTarget.classList.add("submitting")
    }
  }

  submitEnd(event) {
    // Re-enable if the request failed (card wasn't replaced)
    if (this.hasQuickWaterBtnTarget) {
      this.quickWaterBtnTarget.disabled = false
      this.quickWaterBtnTarget.classList.remove("submitting")
    }
  }
}
