import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]
  
  connect() {
    console.log("Navbar controller connected")
    // Close menu when clicking outside
    document.addEventListener('click', this.clickOutside.bind(this))
    
    // Close menu when pressing escape
    document.addEventListener('keydown', this.handleKeyDown.bind(this))
    
    // Handle resize events
    window.addEventListener('resize', this.handleResize.bind(this))
    
    // Close on navigation
    document.addEventListener('turbo:visit', this.closeMenu.bind(this))
  }
  
  disconnect() {
    document.removeEventListener('click', this.clickOutside.bind(this))
    document.removeEventListener('keydown', this.handleKeyDown.bind(this))
    window.removeEventListener('resize', this.handleResize.bind(this))
    document.removeEventListener('turbo:visit', this.closeMenu.bind(this))
  }
  
  toggleMenu(event) {
    if (event) event.preventDefault()
    
    if (!this.hasMenuTarget) {
      console.warn('No menu target found for navbar controller')
      return
    }
    
    this.menuTarget.classList.toggle('hidden')
    
    // Update aria-expanded attribute for accessibility
    const button = event?.currentTarget
    if (button && button.hasAttribute('aria-expanded')) {
      const isOpen = !this.menuTarget.classList.contains('hidden')
      button.setAttribute('aria-expanded', isOpen.toString())
      
      // Announce to screen readers
      const statusAnnouncement = document.createElement('div')
      statusAnnouncement.setAttribute('aria-live', 'polite')
      statusAnnouncement.classList.add('sr-only')
      statusAnnouncement.textContent = isOpen ? 'Menu opened' : 'Menu closed'
      document.body.appendChild(statusAnnouncement)
      
      // Remove after announcement
      setTimeout(() => {
        document.body.removeChild(statusAnnouncement)
      }, 1000)
    }
  }
  
  clickOutside(event) {
    if (!this.hasMenuTarget) return
    
    // Only run if menu is visible
    if (this.menuTarget.classList.contains('hidden')) return
    
    // Close menu if click is outside the navbar
    if (!this.element.contains(event.target)) {
      this.closeMenu()
    }
  }
  
  handleKeyDown(event) {
    if (!this.hasMenuTarget) return
    
    if (event.key === 'Escape' && !this.menuTarget.classList.contains('hidden')) {
      this.closeMenu()
      // Restore focus to the toggle button
      this.element.querySelector('[data-action*="navbar#toggleMenu"]')?.focus()
    }
  }
  
  handleResize() {
    // Auto-close mobile menu on larger screens
    if (!this.hasMenuTarget) return
    
    if (window.innerWidth >= 768 && !this.menuTarget.classList.contains('hidden')) {
      this.closeMenu()
    }
  }
  
  closeMenu() {
    if (!this.hasMenuTarget) return
    
    this.menuTarget.classList.add('hidden')
    
    // Update aria-expanded on any toggle buttons
    const toggleButtons = this.element.querySelectorAll('[data-action*="navbar#toggleMenu"]')
    toggleButtons.forEach(button => {
      if (button.hasAttribute('aria-expanded')) {
        button.setAttribute('aria-expanded', 'false')
      }
    })
  }
}