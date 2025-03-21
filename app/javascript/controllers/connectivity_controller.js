import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="connectivity"
export default class extends Controller {
  connect() {
    console.log("Connectivity controller connected")
    this.updateStatus()
    
    // Add event listeners for online/offline events
    window.addEventListener('online', this.updateStatus.bind(this))
    window.addEventListener('offline', this.updateStatus.bind(this))
  }
  
  disconnect() {
    window.removeEventListener('online', this.updateStatus.bind(this))
    window.removeEventListener('offline', this.updateStatus.bind(this))
  }
  
  updateStatus() {
    if (navigator.onLine) {
      this.element.classList.add('hidden')
    } else {
      this.element.classList.remove('hidden')
    }
  }
  
  dismiss() {
    // Hide the indicator when dismissed
    this.element.classList.add('hidden')
    
    // Store the dismissal in sessionStorage
    // This will prevent the indicator from showing again during this session
    sessionStorage.setItem('offline-indicator-dismissed', 'true')
  }
}
