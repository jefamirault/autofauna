import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["volume", "units", "referenceVolume", "referenceUnits",
                    "referenceConcentration", "targetConcentration", "results"]
  static values = { url: String }

  calculate() {
    const volume = this.volumeTarget.value
    if (!volume || parseFloat(volume) <= 0) {
      this.resultsTarget.innerHTML = ""
      return
    }

    const params = new URLSearchParams({
      volume: volume,
      units: this.unitsTarget.value,
      reference_volume: this.referenceVolumeTarget.value || "1",
      reference_units: this.referenceUnitsTarget.value,
    })

    if (this.referenceConcentrationTarget.value && this.targetConcentrationTarget.value) {
      params.set("reference_concentration", this.referenceConcentrationTarget.value)
      params.set("concentration", this.targetConcentrationTarget.value)
    }

    fetch(`${this.urlValue}?${params}`, {
      headers: { "Accept": "application/json" }
    })
      .then(r => r.json())
      .then(data => {
        if (data.results && data.results.length > 0) {
          this.renderResults(data.results)
        } else {
          this.resultsTarget.innerHTML = "<p>This recipe has no ingredients to calculate.</p>"
        }
      })
      .catch(() => {
        this.resultsTarget.innerHTML = "<p>Could not compute results.</p>"
      })
  }

  renderResults(results) {
    let html = `
      <div class="calculator-results">
        <h3>Ingredients Needed</h3>
        <table class="timeline">
          <thead><tr><th>Ingredient</th><th>Amount</th></tr></thead>
          <tbody>
    `
    results.forEach(r => {
      const amount = parseFloat(r.amount)
      const formatted = amount % 1 === 0 ? amount.toString() : parseFloat(amount.toFixed(3)).toString()
      html += `<tr><td>${r.source_name}</td><td>${formatted} ${r.units}</td></tr>`
    })
    html += `</tbody></table></div>`
    this.resultsTarget.innerHTML = html
  }
}
