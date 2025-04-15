import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="dropdown"
export default class DropdownController extends Controller {
  static targets = ["menu"]
  
  connect() {
    console.log("Dropdown controller connected", this.element);
    // Make sure dropdowns start hidden
    if (this.hasMenuTarget) {
      this.hideMenu();
    }
  }
  
  disconnect() {
    // Clean up any event listeners if needed
  }
  
  toggle(event) {
    // Prevent default behavior
    event.preventDefault();
    console.log("Dropdown toggle called", this.element);
    
    if (!this.hasMenuTarget) {
      console.error("Menu target not found for", this.element);
      return;
    }
    
    const isHidden = this.menuTarget.classList.contains('hidden');
    
    if (isHidden) {
      this.showMenu();
    } else {
      this.hideMenu();
    }
  }
  
  hide(event) {
    // Hide dropdown when clicking outside
    if (this.hasMenuTarget && !this.element.contains(event.target)) {
      this.hideMenu();
    }
  }
  
  // Helper to show menu with animation
  showMenu() {
    this.menuTarget.classList.remove('hidden');
    // Use setTimeout to ensure the transition happens after the display change
    setTimeout(() => {
      this.menuTarget.classList.remove('opacity-0', 'scale-95', 'pointer-events-none');
      this.menuTarget.classList.add('opacity-100', 'scale-100', 'pointer-events-auto');
    }, 10);
  }
  
  // Helper to hide menu with animation
  hideMenu() {
    if (this.hasMenuTarget) {
      this.menuTarget.classList.add('opacity-0', 'scale-95', 'pointer-events-none');
      this.menuTarget.classList.remove('opacity-100', 'scale-100', 'pointer-events-auto');
      
      // Wait for animation to complete before hiding
      setTimeout(() => {
        this.menuTarget.classList.add('hidden');
      }, 150);
    }
  }
}
