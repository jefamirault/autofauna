import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static values = {
        url: String
    }

    goToUrl(){
        Turbo.visit(this.urlValue)
    }
}