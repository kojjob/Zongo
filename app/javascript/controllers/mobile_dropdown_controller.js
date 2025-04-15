import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="mobile-dropdown"
export default class MobileDropdownController extends Controller {
  static targets = ["menu", "icon"]
  
  connect() {
    console.log("Mobile dropdown controller connected", this.element);
  }
  
  toggle(event) {
    event.preventDefault();
    console.log("Mobile dropdown toggle called", this.element);
    
    if (!this.hasMenuTarget) {
      console.error("Menu target not found for", this.element);
      return;
    }
    
    if (!this.hasIconTarget) {
      console.error("Icon target not found for", this.element);
    }
    
    // Toggle the menu visibility
    this.menuTarget.classList.toggle('hidden');
    
    // Rotate the icon if available
    if (this.hasIconTarget) {
      this.iconTarget.classList.toggle('rotate-180');
    }
  }
}
