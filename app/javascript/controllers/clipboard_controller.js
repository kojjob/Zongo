import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    successMessage: { type: String, default: 'Copied to clipboard!' },
    timeout: { type: Number, default: 2000 }
  }
  
  copy(event) {
    event.preventDefault()
    
    const text = event.currentTarget.dataset.clipboardText
    
    if (!text) return
    
    navigator.clipboard.writeText(text).then(() => {
      // Get or create toast notification
      const originalText = event.currentTarget.textContent.trim()
      
      // Show success indicator
      const originalIcon = event.currentTarget.querySelector('svg').outerHTML
      event.currentTarget.innerHTML = `
        <svg class="h-5 w-5 mr-3 text-green-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
        </svg>
        Copied!
      `
      
      // Reset after timeout
      setTimeout(() => {
        event.currentTarget.innerHTML = originalIcon + 'Copy Event Link'
      }, this.timeoutValue)
    })
  }
}
