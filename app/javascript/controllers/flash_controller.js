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
    }, 300)
  }
}
