import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["nameInput", "graphicSelect", "preview", "suggestions"]
  static values = {
    suggestUrl: String,
    paths: Object
  }

  connect() {
    this.debounceTimer = null
    this.manuallySelected = false
    this.activeIndex = -1
    this.updatePreview()

    this.graphicNames = Object.keys(this.pathsValue)

    this._onDocumentClick = (e) => {
      if (!this.element.contains(e.target)) this.closeSuggestions()
    }
    document.addEventListener("click", this._onDocumentClick)
  }

  disconnect() {
    document.removeEventListener("click", this._onDocumentClick)
  }

  humanize(name) {
    return name.replace(/_/g, " ").replace(/\b\w/, c => c.toUpperCase())
  }

  nameChanged() {
    this.showSuggestions()

    // Don't auto-suggest if user has manually selected a graphic
    if (this.manuallySelected) {
      return
    }

    // Clear existing timer
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer)
    }

    // Debounce the API call
    this.debounceTimer = setTimeout(() => {
      this.fetchGraphicSuggestion()
    }, 300)
  }

  showSuggestions() {
    const query = this.nameInputTarget.value.trim().toLowerCase()
    const list = this.suggestionsTarget

    if (!query) {
      this.closeSuggestions()
      return
    }

    const matches = this.graphicNames.filter(n =>
      this.humanize(n).toLowerCase().includes(query)
    )

    if (matches.length === 0) {
      this.closeSuggestions()
      return
    }

    this.activeIndex = -1
    list.innerHTML = matches.map((name, i) => {
      const path = this.pathsValue[name]
      return `<li data-index="${i}" data-graphic="${name}" class="autocomplete-item">
        <img src="${path}" class="autocomplete-thumb" alt="" />
        <span>${this.humanize(name)}</span>
      </li>`
    }).join("")

    list.style.display = "block"

    list.querySelectorAll("li").forEach(li => {
      li.addEventListener("mousedown", (e) => {
        e.preventDefault()
        this.selectGraphic(li.dataset.graphic)
      })
    })
  }

  closeSuggestions() {
    this.suggestionsTarget.style.display = "none"
    this.suggestionsTarget.innerHTML = ""
    this.activeIndex = -1
  }

  selectGraphic(name) {
    this.nameInputTarget.value = this.humanize(name)
    this.graphicSelectTarget.value = name
    this.manuallySelected = true
    this.updatePreview()
    this.closeSuggestions()
  }

  nameKeydown(event) {
    const list = this.suggestionsTarget
    const items = list.querySelectorAll("li")

    if (event.key === "Tab") {
      if (items.length && list.style.display !== "none") {
        event.preventDefault()
        this.selectGraphic(items[0].dataset.graphic)
      }
      return
    }

    if (!items.length || list.style.display === "none") return

    if (event.key === "ArrowDown") {
      event.preventDefault()
      this.activeIndex = Math.min(this.activeIndex + 1, items.length - 1)
      this.highlightItem(items)
    } else if (event.key === "ArrowUp") {
      event.preventDefault()
      this.activeIndex = Math.max(this.activeIndex - 1, 0)
      this.highlightItem(items)
    } else if (event.key === "Enter" && this.activeIndex >= 0) {
      event.preventDefault()
      this.selectGraphic(items[this.activeIndex].dataset.graphic)
    } else if (event.key === "Escape") {
      this.closeSuggestions()
    }
  }

  highlightItem(items) {
    items.forEach((li, i) => {
      li.classList.toggle("active", i === this.activeIndex)
    })
  }

  async fetchGraphicSuggestion() {
    const name = this.nameInputTarget.value

    if (!name || name.trim() === "") {
      return
    }

    try {
      const url = `${this.suggestUrlValue}?name=${encodeURIComponent(name)}`
      const response = await fetch(url)
      const data = await response.json()

      if (data.graphic) {
        // Only update if user hasn't manually selected
        if (!this.manuallySelected) {
          this.graphicSelectTarget.value = data.graphic
          this.updatePreview()
        }
      }
    } catch (error) {
      console.error("Error fetching graphic suggestion:", error)
    }
  }

  graphicChanged() {
    this.manuallySelected = true
    this.updatePreview()
  }

  updatePreview() {
    const selectedGraphic = this.graphicSelectTarget.value

    if (selectedGraphic && selectedGraphic !== "" && this.pathsValue[selectedGraphic]) {
      this.previewTarget.src = this.pathsValue[selectedGraphic]
      this.previewTarget.style.display = "block"
    } else {
      this.previewTarget.style.display = "none"
    }
  }
}
