import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["preButton", "postButton", "preField", "postField"]

  togglePre() {
    this.preFieldTarget.style.display = "block"
    this.preButtonTarget.style.display = "none"
  }

  togglePost() {
    this.postFieldTarget.style.display = "block"
    this.postButtonTarget.style.display = "none"
  }

  hidePre() {
    this.preFieldTarget.style.display = "none"
    this.preButtonTarget.style.display = "inline-block"

    // Clear the input value
    const input = this.preFieldTarget.querySelector("input, select")
    if (input) input.value = ""
  }

  hidePost() {
    this.postFieldTarget.style.display = "none"
    this.postButtonTarget.style.display = "inline-block"

    // Clear the input value
    const input = this.postFieldTarget.querySelector("input, select")
    if (input) input.value = ""
  }
}
