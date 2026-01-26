// app/javascript/controllers/clickable_row_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static values = {
        url: String
    }

    connect() {
        this.element.classList.add("cursor-pointer")
    }

    click(event) {
        // Prevent click if we're clicking on a button, link, or form element
        if (this.isIgnorableClick(event)) {
            return
        }

        // Prevent click if user is selecting text
        const selection = window.getSelection()
        if (selection && selection.toString().length > 0) {
            return
        }

        Turbo.visit(this.urlValue)
    }

    isIgnorableClick(event) {
        const ignorableElements = ['a', 'button', 'input', 'select', 'textarea']
        const element = event.target

        return (
            ignorableElements.includes(element.tagName.toLowerCase()) ||
            element.closest('a, button, input, select, textarea') !== null
        )
    }
}