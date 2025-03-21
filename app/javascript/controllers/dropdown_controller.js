import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="dropdown"
export default class extends Controller {
  static targets = ["menu"]
  
  connect() {
    console.log("Dropdown controller connected")
    // Close dropdown when clicking outside
    document.addEventListener('click', this.closeIfClickedOutside.bind(this))
    
    // Close dropdown when pressing escape
    document.addEventListener('keydown', this.handleKeyDown.bind(this))
    
    // Close on navigation
    document.addEventListener('turbo:visit', this.closeAllMenus.bind(this))
    
    // Initial state ensuring the menu is hidden
    if (this.hasMenuTarget) {
      this.menuTarget.classList.add('hidden')
    }
  }
  
  disconnect() {
    document.removeEventListener('click', this.closeIfClickedOutside.bind(this))
    document.removeEventListener('keydown', this.handleKeyDown.bind(this))
    document.removeEventListener('turbo:visit', this.closeAllMenus.bind(this))
  }
  
  toggle(event) {
    event.stopPropagation()
    
    if (!this.hasMenuTarget) {
      console.warn('No menu target found for dropdown controller')
      return
    }
    
    // Close all other dropdowns
    this.closeOtherDropdowns()
    
    // Toggle this dropdown
    this.menuTarget.classList.toggle('hidden')
    
    // Set focus to the first focusable element when opened
    if (!this.menuTarget.classList.contains('hidden')) {
      // Add a slight delay to ensure the menu is visible first
      setTimeout(() => {
        const focusableElements = this.menuTarget.querySelectorAll(
          'a[href], button, input, textarea, select, details, [tabindex]:not([tabindex="-1"])'
        )
        if (focusableElements.length > 0) {
          focusableElements[0].focus()
        }
      }, 50)
    }
  }
  
  // Close dropdown when clicking outside
  closeIfClickedOutside(event) {
    if (!this.hasMenuTarget) return
    
    if (!this.element.contains(event.target) && !this.menuTarget.classList.contains('hidden')) {
      this.menuTarget.classList.add('hidden')
    }
  }
  
  // Close dropdown on escape key
  handleKeyDown(event) {
    if (!this.hasMenuTarget) return
    
    if (event.key === 'Escape' && !this.menuTarget.classList.contains('hidden')) {
      this.menuTarget.classList.add('hidden')
      // Restore focus to the toggle button
      this.element.querySelector('[data-action*="dropdown#toggle"]')?.focus()
    }
  }
  
  // Close all dropdowns except this one
  closeOtherDropdowns() {
    const allDropdowns = document.querySelectorAll('[data-controller="dropdown"]')
    allDropdowns.forEach(dropdown => {
      if (dropdown !== this.element) {
        const menuElement = dropdown.querySelector('[data-dropdown-target="menu"]')
        if (menuElement && !menuElement.classList.contains('hidden')) {
          menuElement.classList.add('hidden')
        }
      }
    })
  }
  
  // Close all menus
  closeAllMenus() {
    if (this.hasMenuTarget) {
      this.menuTarget.classList.add('hidden')
    }
  }
}
