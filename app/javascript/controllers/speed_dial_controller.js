import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="speed-dial"
export default class extends Controller {
  static targets = ["menu", "button"]
  
  connect() {
    console.log("Speed dial controller connected")
    // Store bound functions as instance properties to allow proper cleanup
    this.boundCloseIfClickedOutside = this.closeIfClickedOutside.bind(this)
    this.boundHandleKeyDown = this.handleKeyDown.bind(this)
    
    // Close menu when clicking outside
    document.addEventListener('click', this.boundCloseIfClickedOutside)
    
    // Close menu when pressing escape
    document.addEventListener('keydown', this.boundHandleKeyDown)
    
    // Ensure the menu is initially hidden
    if (this.hasMenuTarget) {
      this.menuTarget.classList.add('hidden')
    }
  }
  
  disconnect() {
    document.removeEventListener('click', this.boundCloseIfClickedOutside)
    document.removeEventListener('keydown', this.boundHandleKeyDown)
  }
  
  toggle(event) {
    event.preventDefault()
    event.stopPropagation()
    
    if (!this.hasMenuTarget) {
      console.warn('No menu target found for speed dial controller')
      return
    }
    
    // Toggle the menu visibility
    const isHidden = this.menuTarget.classList.contains('hidden')
    
    if (isHidden) {
      // Opening menu
      this.menuTarget.classList.remove('hidden')
      this.menuTarget.classList.add('animate-scale-in')
      
      // Update ARIA attributes
      if (this.hasButtonTarget) {
        this.buttonTarget.setAttribute('aria-expanded', 'true')
      }
      
      // Add a ripple effect to the button when clicked
      this.addRippleEffect(event)
      
      // Focus the first focusable element in the menu
      setTimeout(() => {
        const firstFocusable = this.menuTarget.querySelector('a, button, input, [tabindex]:not([tabindex="-1"])')
        if (firstFocusable) {
          firstFocusable.focus()
        }
      }, 100)
    } else {
      // Closing menu
      this.closeMenu()
    }
  }
  
  closeIfClickedOutside(event) {
    if (!this.hasMenuTarget) return
    
    // Only run if menu is visible
    if (this.menuTarget.classList.contains('hidden')) return
    
    // Close menu if click is outside the controller element
    if (!this.element.contains(event.target)) {
      this.closeMenu()
    }
  }
  
  handleKeyDown(event) {
    if (!this.hasMenuTarget) return
    
    if (event.key === 'Escape' && !this.menuTarget.classList.contains('hidden')) {
      this.closeMenu()
      
      // Return focus to the button
      if (this.hasButtonTarget) {
        this.buttonTarget.focus()
      }
    }
  }
  
  closeMenu() {
    if (!this.hasMenuTarget) return
    
    this.menuTarget.classList.add('hidden')
    this.menuTarget.classList.remove('animate-scale-in')
    
    // Update ARIA attributes
    if (this.hasButtonTarget) {
      this.buttonTarget.setAttribute('aria-expanded', 'false')
    }
  }
  
  // Helper method to add a ripple effect to the button when clicked
  addRippleEffect(event) {
    const button = event.currentTarget
    
    // Create ripple element
    const ripple = document.createElement('span')
    ripple.classList.add('absolute', 'inset-0', 'rounded-full', 'bg-white', 'opacity-30', 'animate-ping-slow')
    
    // Add ripple to button
    button.appendChild(ripple)
    
    // Remove ripple after animation completes
    setTimeout(() => {
      ripple.remove()
    }, 1000)
  }
}