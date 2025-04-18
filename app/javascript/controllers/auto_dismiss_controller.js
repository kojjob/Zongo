import { Controller } from "@hotwired/stimulus"

/**
 * Auto-dismiss Controller
 *
 * Automatically dismisses elements (like flash messages) after a specified timeout
 * Also provides a method to manually dismiss the element
 */
export default class extends Controller {
  static targets = ["progressBar"]
  static values = {
    delay: { type: Number, default: 5000 },
    type: String
  }

  connect() {
    // Start the progress bar animation if it exists
    if (this.hasProgressBarTarget) {
      this.progressBarTarget.style.width = "100%"
      this.progressBarTarget.style.transition = `width ${this.delayValue}ms linear`

      // Use setTimeout to allow the browser to render the initial state
      setTimeout(() => {
        this.progressBarTarget.style.width = "0%"
      }, 10)
    }

    // Set up auto-dismiss timer
    this.dismissTimer = setTimeout(() => {
      this.dismiss()
    }, this.delayValue)

    // Add event listener for ESC key
    this.handleKeyDown = this.handleKeyDown.bind(this)
    document.addEventListener('keydown', this.handleKeyDown)
  }

  disconnect() {
    // Clear the timeout if the element is removed from the DOM
    if (this.dismissTimer) {
      clearTimeout(this.dismissTimer)
    }

    // Remove event listener
    document.removeEventListener('keydown', this.handleKeyDown)
  }

  handleKeyDown(event) {
    if (event.key === "Escape") {
      this.dismiss()
    }
  }

  dismiss() {
    // Clear the timeout to prevent multiple dismissals
    if (this.dismissTimer) {
      clearTimeout(this.dismissTimer)
      this.dismissTimer = null
    }

    // Animate the dismissal
    this.element.style.opacity = "0"
    this.element.style.transform = "translateY(-10px)"
    this.element.style.transition = "opacity 300ms ease, transform 300ms ease"

    // Remove from DOM after animation
    setTimeout(() => {
      this.element.remove()

      // Check if this was the last flash message
      const flashContainer = document.getElementById('flash-messages')
      if (flashContainer && flashContainer.children.length === 0) {
        flashContainer.remove()
      }
    }, 300)
  }
}
