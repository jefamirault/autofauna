import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["chip", "select", "hidden", "details"]

  pickSuggestion(event) {
    const btn = event.currentTarget
    const id = btn.dataset.id

    this.hiddenTarget.value = id

    this.chipTargets.forEach(c => c.classList.remove("selected"))
    btn.classList.add("selected")

    if (this.hasSelectTarget) {
      this.selectTarget.value = id
    }

    this.dispatch("changed", { detail: { id } })
  }

  selectChanged() {
    const id = this.selectTarget.value
    this.hiddenTarget.value = id

    this.chipTargets.forEach(c => {
      c.classList.toggle("selected", c.dataset.id === id)
    })

    this.dispatch("changed", { detail: { id } })
  }
}
