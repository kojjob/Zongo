import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    delay: { type: Number, default: 3000 }
  }

  connect() {
    // Set a timeout to auto-dismiss the flash message
    if (this.delayValue > 0) {
      this.dismissTimer = setTimeout(() => {
        this.dismiss()
      }, this.delayValue)
    }
  }

  disconnect() {
    // Clean up timer if element is removed from DOM
    if (this.dismissTimer) {
      clearTimeout(this.dismissTimer)
    }
  }

  dismiss() {
    // Animate the dismissal
    this.element.classList.add("opacity-0", "transition-opacity", "duration-300")

    // Remove from DOM after animation
    setTimeout(() => {
      this.element.remove()

      // Check if this was the last flash message
      const flashContainer = document.querySelector('.flash-container')
      if (flashContainer && flashContainer.querySelectorAll('[data-controller="flash"]').length === 0) {
        flashContainer.remove()
      }

      // Clear the flash from the session via AJAX
      this.clearFlashFromSession()
    }, 300)
  }

  clearFlashFromSession() {
    // Send a request to clear the flash message from the session
    fetch('/clear_flash', {
      method: 'POST',
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
        'Content-Type': 'application/json'
      }
    })
  }
}
