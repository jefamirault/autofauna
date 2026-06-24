import { Controller } from "@hotwired/stimulus"

// Drives the multi-step onboarding wizard: step navigation, the conditional
// fertilizer-names step, and dynamic fertilizer rows. Submits once at the end.
export default class extends Controller {
  static targets = [
    "step", "progress", "plantsCheckbox", "aquariumCheckbox",
    "fertilizerCheckbox", "fertilizerRows", "otherEntry", "otherToggle", "tankOption",
    "noFertilizer", "fertilizerOption"
  ]

  connect() {
    this.index = 0
    this.render()
  }

  // Steps that are active given current answers (skips the fertilizer step
  // unless the user said they use fertilizer).
  sequence() {
    return this.stepTargets.filter((step) => {
      if (step.dataset.onboardingOptional === "fertilizer") {
        return this.hasFertilizerCheckboxTarget && this.fertilizerCheckboxTarget.checked
      }
      return true
    })
  }

  next() {
    const seq = this.sequence()
    if (this.index < seq.length - 1) {
      this.index++
      this.render()
    }
  }

  back() {
    if (this.index > 0) {
      this.index--
      this.render()
    }
  }

  fertilizerToggled() {
    // Sequence length may have changed; keep the index in range.
    this.render()
  }

  // "Don't water with fertilizer" is mutually exclusive with the actual
  // fertilizer choices: checking it clears every other selection.
  noFertilizerToggled() {
    if (!this.noFertilizerTarget.checked) return
    this.fertilizerOptionTargets.forEach((cb) => { cb.checked = false })
    if (this.hasFertilizerRowsTarget) {
      this.fertilizerRowsTarget
        .querySelectorAll("input")
        .forEach((input) => { input.value = "" })
    }
  }

  // Picking any real fertilizer (checkbox or manual entry) unchecks the
  // mutually-exclusive "Don't water with fertilizer" option.
  fertilizerSelected(event) {
    const el = event.target
    const active = el.type === "checkbox" ? el.checked : el.value.trim().length > 0
    if (active && this.hasNoFertilizerTarget) this.noFertilizerTarget.checked = false
  }

  // Don't let Enter inside a text field submit the form before the final step.
  keydown(event) {
    if (event.key !== "Enter") return
    const seq = this.sequence()
    if (this.index < seq.length - 1) event.preventDefault()
  }

  // Reveal/hide the manual "Other" entry rows. Manual entry is optional —
  // the list of common fertilizers above is enough to proceed.
  toggleOther() {
    const entry = this.otherEntryTarget
    const show = entry.hidden
    entry.hidden = !show
    if (this.hasOtherToggleTarget) {
      this.otherToggleTarget.setAttribute("aria-expanded", show ? "true" : "false")
    }
    if (show) entry.querySelector("input")?.focus()
  }

  addFertilizer() {
    const rows = this.fertilizerRowsTarget
    const template = rows.querySelector(".onboarding-fertilizer-row")
    const clone = template.cloneNode(true)
    clone.querySelector("input").value = ""
    rows.appendChild(clone)
    clone.querySelector("input").focus()
  }

  removeFertilizer(event) {
    const rows = this.fertilizerRowsTarget
    const row = event.target.closest(".onboarding-fertilizer-row")
    if (row && rows.querySelectorAll(".onboarding-fertilizer-row").length > 1) {
      row.remove()
    } else if (row) {
      row.querySelector("input").value = ""
    }
  }

  render() {
    const seq = this.sequence()
    this.index = Math.max(0, Math.min(this.index, seq.length - 1))

    this.stepTargets.forEach((step) => { step.hidden = true })
    const current = seq[this.index]
    if (current) current.hidden = false

    if (this.hasProgressTarget) {
      this.progressTarget.textContent = `${this.index + 1} / ${seq.length}`
    }

    if (this.hasTankOptionTarget) {
      this.tankOptionTarget.hidden =
        !(this.hasAquariumCheckboxTarget && this.aquariumCheckboxTarget.checked)
    }
  }
}
