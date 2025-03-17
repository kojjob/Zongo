import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]
  
  connect() {
    // Close menu when clicking outside
    document.addEventListener('click', this.clickOutside.bind(this))
  }
  
  disconnect() {
    document.removeEventListener('click', this.clickOutside.bind(this))
  }
  
  toggleMenu() {
    this.menuTarget.classList.toggle('hidden')
  }
  
  clickOutside(event) {
    // Only run if menu is visible
    if (this.menuTarget.classList.contains('hidden')) return
    
    // Close menu if click is outside the navbar
    if (!this.element.contains(event.target)) {
      this.menuTarget.classList.add('hidden')
    }
  }
}