import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "spinner", "text"]

  connect() {
    // Keep track of original button text
    if (this.hasTextTarget) {
      this.originalText = this.textTarget.textContent
    }
  }

  start() {
    // Disable the button and show spinner
    if (this.hasButtonTarget) {
      this.buttonTarget.disabled = true
      this.buttonTarget.classList.add("opacity-75", "cursor-wait")
    }
    
    // Show the spinner if we have one
    if (this.hasSpinnerTarget) {
      this.spinnerTarget.classList.remove("hidden")
    }
    
    // Update text if we have a text target
    if (this.hasTextTarget) {
      this.textTarget.textContent = this.textTarget.dataset.loadingText || "Processing..."
    }
  }

  stop() {
    // Re-enable the button and hide spinner
    if (this.hasButtonTarget) {
      this.buttonTarget.disabled = false
      this.buttonTarget.classList.remove("opacity-75", "cursor-wait")
    }
    
    // Hide the spinner if we have one
    if (this.hasSpinnerTarget) {
      this.spinnerTarget.classList.add("hidden")
    }
    
    // Restore original text
    if (this.hasTextTarget && this.originalText) {
      this.textTarget.textContent = this.originalText
    }
  }
}
