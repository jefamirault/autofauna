import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["template", "container", "row"]

  add(event) {
    event.preventDefault()
    const content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, new Date().getTime())
    this.containerTarget.insertAdjacentHTML("beforeend", content)
  }

  remove(event) {
    event.preventDefault()
    const row = event.target.closest("[data-nested-form-target='row']")
    const destroyField = row.querySelector(".destroy-field")

    if (destroyField) {
      destroyField.value = "true"
      row.style.display = "none"
    } else {
      row.remove()
    }
  }
}
