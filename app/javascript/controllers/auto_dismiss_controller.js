import { Controller } from "@hotwired/stimulus"

/**
 * Auto-dismiss Controller
 * 
 * Automatically dismisses elements (like flash messages) after a specified timeout
 * Also provides a method to manually dismiss the element
 */
export default class extends Controller {
  static targets = ["flash"]
  
  connect() {
    // Get timeout from data attribute or default to 5000ms (5 seconds)
    const timeout = this.element.dataset.autoDismissTimeout || 5000
    
    // Set timeout to auto-dismiss
    this.dismissTimer = setTimeout(() => {
      this.dismiss()
    }, timeout)
  }
  
  disconnect() {
    // Clear the timeout if the element is removed from the DOM
    if (this.dismissTimer) {
      clearTimeout(this.dismissTimer)
    }
  }
  
  dismiss() {
    // Fade out the element
    this.element.classList.add('opacity-0')
    this.element.style.transition = 'opacity 0.5s ease'
    
    // Remove the element after fade completes
    setTimeout(() => {
      this.element.remove()
    }, 500)
  }
}
