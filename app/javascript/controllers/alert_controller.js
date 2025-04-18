import { Controller } from "@hotwired/stimulus"

// This controller handles dismissable alerts
export default class extends Controller {
  connect() {
    // Check if this alert was already dismissed (using localStorage)
    const alertId = this.element.dataset.alertId
    if (alertId && localStorage.getItem(`dismissed_alert_${alertId}`)) {
      this.element.remove()
    }
  }
  
  dismiss() {
    // Optional: Remember this dismissal in localStorage if the alert has an ID
    const alertId = this.element.dataset.alertId
    if (alertId) {
      localStorage.setItem(`dismissed_alert_${alertId}`, 'true')
    }
    
    // Fade out and remove the alert
    this.element.classList.add('opacity-0', 'transition-opacity', 'duration-300')
    
    // After transition completes, remove the element from DOM
    setTimeout(() => {
      this.element.remove()
    }, 300)
  }
}
