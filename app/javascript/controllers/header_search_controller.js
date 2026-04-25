import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.timeout = null
    const form = this.element.querySelector("form")
    if (form) {
      this._submitHandler = () => this._injectFilterParams(form)
      form.addEventListener("submit", this._submitHandler)
    }
  }

  search() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      this.element.querySelector("form").requestSubmit()
    }, 300)
  }

  disconnect() {
    clearTimeout(this.timeout)
    const form = this.element.querySelector("form")
    if (form && this._submitHandler) {
      form.removeEventListener("submit", this._submitHandler)
    }
  }

  _injectFilterParams(form) {
    form.querySelectorAll("input[data-filter-preserved]").forEach(el => el.remove())
    const current = new URLSearchParams(window.location.search)
    ;["locations[]", "recipes[]", "status[]", "display"].forEach(key => {
      current.getAll(key).forEach(val => {
        const input = document.createElement("input")
        input.type = "hidden"
        input.name = key
        input.value = val
        input.dataset.filterPreserved = "true"
        form.appendChild(input)
      })
    })
  }
}
