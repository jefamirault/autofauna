import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["waterCol", "inlineForm", "expandToggle", "quickWaterBtn"]

  expand(event) {
    event.preventDefault()
    event.stopPropagation()
    this.waterColTarget.style.display = "none"
    this.inlineFormTarget.style.display = ""
    // Focus the first visible input
    const firstInput = this.inlineFormTarget.querySelector("input:not([type='hidden']), select, textarea")
    if (firstInput) firstInput.focus()
  }

  collapse(event) {
    if (event) event.preventDefault()
    this.inlineFormTarget.style.display = "none"
    this.waterColTarget.style.display = ""
  }

  submitStart(event) {
    // Disable the quick water button to prevent double-submission
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
