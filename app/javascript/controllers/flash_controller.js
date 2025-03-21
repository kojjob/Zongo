import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["message"]
  
  connect() {
    // Auto-dismiss flash messages after a delay
    this.messageTargets.forEach(message => {
      setTimeout(() => {
        this.dismissMessage(message)
      }, 5000) // 5 seconds
    })
  }
  
  closeMessage(event) {
    const message = event.target.closest("[data-flash-target='message']")
    this.dismissMessage(message)
  }
  
  dismissMessage(message) {
    // Only dismiss if the message still exists
    if (!message || !message.parentElement) return
    
    // Add exit animation class
    message.classList.add('opacity-0', '-translate-y-2')
    
    // Remove after animation completes
    setTimeout(() => {
      if (message.parentElement) {
        message.remove()
      }
    }, 300)
  }
}