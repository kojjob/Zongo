import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    debounceMs: { type: Number, default: 300 }
  }

  initialize() {
    // Create a debounced version of the submit function
    this.debouncedSubmit = this.debounce(this.submit.bind(this), this.debounceMs)
  }

  // Debounce function to limit how often the search is performed
  debounce(func, wait) {
    let timeout
    return function() {
      const context = this
      const args = arguments
      clearTimeout(timeout)
      timeout = setTimeout(() => {
        func.apply(context, args)
      }, wait)
    }
  }

  // Called when input changes, debounces the submit
  debounce(event) {
    this.debouncedSubmit()
  }

  // Submits the form
  submit() {
    this.element.requestSubmit()
  }
}
