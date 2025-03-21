import { Controller } from "@hotwired/stimulus"

// Simplified dropdown controller - basic functionality only
export default class extends Controller {
  static targets = ["menu"]

  connect() {
    console.log("Dropdown Simple controller connected!")
    // Ensure menu starts hidden
    if (this.hasMenuTarget) {
      this.menuTarget.classList.add("hidden")
    }
  }

  toggle(event) {
    event.preventDefault()
    event.stopPropagation()
    
    console.log("Toggling dropdown...")
    
    if (!this.hasMenuTarget) {
      console.warn("No menu target found!")
      return
    }
    
    // Toggle visibility
    this.menuTarget.classList.toggle("hidden")
    
    // Set up a click outside listener if menu is now visible
    if (!this.menuTarget.classList.contains("hidden")) {
      document.addEventListener("click", this.outsideClickHandler = this.outsideClickHandler || this.handleOutsideClick.bind(this), { once: true })
    }
  }
  
  handleOutsideClick(event) {
    // If click is outside the controller element
    if (!this.element.contains(event.target) && this.hasMenuTarget) {
      this.menuTarget.classList.add("hidden")
      console.log("Closed dropdown via outside click")
    } else if (!this.menuTarget.classList.contains("hidden")) {
      // Re-register the handler if menu is still open
      document.addEventListener("click", this.outsideClickHandler, { once: true })
    }
  }
}
