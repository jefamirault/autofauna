import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["picker", "toggleBtn"]

  toggle() {
    const picker = this.pickerTarget
    const isVisible = picker.style.display !== "none"
    picker.style.display = isVisible ? "none" : "flex"
  }
}
