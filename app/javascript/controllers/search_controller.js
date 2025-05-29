import { Controller } from "@hotwired/stimulus"

// Handles search functionality on Enter key press
export default class extends Controller {

  handleKey(event) {
    if (event.key === "Enter") {
      event.preventDefault()
      this.element.requestSubmit()
    }
  }

  submit() {
    this.element.requestSubmit()
  }
}
