import { Controller } from "@hotwired/stimulus"

// Handles live search functionality
export default class extends Controller {
  static values = {
    debounce: { type: Number, default: 3000 }
  }

  initialize() {
    // console.log('Search controller initialized')
    this.debounced = this.debounce.bind(this)
  }

  submit() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      this.element.requestSubmit()
    }, this.debounceValue)
  }

  debounce(event) {
    if (event.key === "Enter") return

    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      this.element.requestSubmit()
    }, this.debounceValue)
  }
}
