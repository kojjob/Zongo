import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["label", "loader", "icon"]
  
  static values = {
    loadingText: String
  }
  
  startLoading() {
    // Store original button state
    this._originalHtml = this.labelTarget.innerHTML
    
    // Show loading indicator
    this.labelTarget.innerHTML = this.loadingTextValue || 'Loading...'
    this.loaderTarget.classList.remove('opacity-0')
    this.loaderTarget.classList.add('opacity-100')
    
    // Hide icon if present
    if (this.hasIconTarget) {
      this.iconTarget.classList.add('opacity-0')
    }
    
    // Let the form submission proceed
  }
  
  stopLoading() {
    // Restore original button state
    if (this._originalHtml) {
      this.labelTarget.innerHTML = this._originalHtml
    }
    
    this.loaderTarget.classList.remove('opacity-100')
    this.loaderTarget.classList.add('opacity-0')
    
    // Show icon if present
    if (this.hasIconTarget) {
      this.iconTarget.classList.remove('opacity-0')
    }
  }
}