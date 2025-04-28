import { Controller } from "@hotwired/stimulus"

/**
 * Accessibility Controller
 * 
 * This controller handles various accessibility features throughout the application:
 * - Focus management
 * - Keyboard navigation
 * - Screen reader announcements
 * - Accessible modals
 * - Skip links
 */
export default class extends Controller {
  static targets = [
    "focusTrap",      // Container to trap focus within (e.g., modal)
    "announcement",   // Element for screen reader announcements
    "skipLink",       // Skip navigation link
    "focusable",      // Elements that should receive focus
    "modal"           // Modal container
  ]

  static values = {
    trapActive: Boolean,  // Whether focus trapping is active
    returnFocusTo: String // Selector for element to return focus to when trap is deactivated
  }

  connect() {
    // Initialize focus trap if active
    if (this.trapActiveValue && this.hasFocusTrapTarget) {
      this.activateFocusTrap()
    }

    // Initialize skip links
    if (this.hasSkipLinkTarget) {
      this.initializeSkipLinks()
    }

    // Add keyboard event listeners for modal if present
    if (this.hasModalTarget) {
      this.initializeAccessibleModal()
    }
  }

  disconnect() {
    // Clean up event listeners
    if (this._keyDownHandler) {
      document.removeEventListener('keydown', this._keyDownHandler)
    }
  }

  // Activate focus trap for modals and dialogs
  activateFocusTrap() {
    // Store the element that had focus before trapping
    this._previouslyFocused = document.activeElement

    // Set up the keydown handler for focus trapping
    this._keyDownHandler = this.handleKeyDown.bind(this)
    document.addEventListener('keydown', this._keyDownHandler)

    // Get all focusable elements within the trap
    this._focusableElements = this.getFocusableElements()

    // Focus the first focusable element
    if (this._focusableElements.length > 0) {
      setTimeout(() => {
        this._focusableElements[0].focus()
      }, 100)
    }

    // Set trap as active
    this.trapActiveValue = true
  }

  // Deactivate focus trap
  deactivateFocusTrap() {
    // Remove keydown handler
    if (this._keyDownHandler) {
      document.removeEventListener('keydown', this._keyDownHandler)
    }

    // Return focus to the previously focused element or specified element
    if (this.returnFocusToValue) {
      const returnElement = document.querySelector(this.returnFocusToValue)
      if (returnElement) {
        returnElement.focus()
      }
    } else if (this._previouslyFocused) {
      this._previouslyFocused.focus()
    }

    // Set trap as inactive
    this.trapActiveValue = false
  }

  // Handle keydown events for focus trapping
  handleKeyDown(event) {
    // Handle Escape key to close modal
    if (event.key === 'Escape' && this.hasModalTarget) {
      this.closeModal()
      return
    }

    // Only handle Tab key for focus trapping
    if (event.key !== 'Tab' || !this.trapActiveValue) return

    // Get all focusable elements
    const focusableElements = this.getFocusableElements()
    if (focusableElements.length === 0) return

    // Get first and last focusable elements
    const firstElement = focusableElements[0]
    const lastElement = focusableElements[focusableElements.length - 1]

    // Handle Tab and Shift+Tab to cycle through focusable elements
    if (event.shiftKey) {
      // If Shift+Tab on first element, move to last element
      if (document.activeElement === firstElement) {
        event.preventDefault()
        lastElement.focus()
      }
    } else {
      // If Tab on last element, move to first element
      if (document.activeElement === lastElement) {
        event.preventDefault()
        firstElement.focus()
      }
    }
  }

  // Get all focusable elements within the focus trap
  getFocusableElements() {
    if (!this.hasFocusTrapTarget) return []

    // Selector for all potentially focusable elements
    const focusableSelector = [
      'a[href]',
      'button:not([disabled])',
      'input:not([disabled])',
      'select:not([disabled])',
      'textarea:not([disabled])',
      '[tabindex]:not([tabindex="-1"])',
      'details',
      'summary',
      '[contenteditable]'
    ].join(',')

    // Get all focusable elements within the trap
    const candidates = Array.from(this.focusTrapTarget.querySelectorAll(focusableSelector))

    // Filter out hidden elements
    return candidates.filter(el => {
      return !!(el.offsetWidth || el.offsetHeight || el.getClientRects().length)
    })
  }

  // Initialize skip links
  initializeSkipLinks() {
    this.skipLinkTargets.forEach(link => {
      link.addEventListener('click', (event) => {
        event.preventDefault()
        
        // Get the target element
        const targetId = link.getAttribute('href')
        const targetElement = document.querySelector(targetId)
        
        if (targetElement) {
          // Make the target focusable if it isn't already
          if (!targetElement.hasAttribute('tabindex')) {
            targetElement.setAttribute('tabindex', '-1')
          }
          
          // Focus the target
          targetElement.focus()
          
          // Scroll to the target
          targetElement.scrollIntoView({ behavior: 'smooth' })
        }
      })
    })
  }

  // Initialize accessible modal
  initializeAccessibleModal() {
    // Set ARIA attributes
    this.modalTarget.setAttribute('role', 'dialog')
    this.modalTarget.setAttribute('aria-modal', 'true')
    
    // If modal has a heading, set aria-labelledby
    const heading = this.modalTarget.querySelector('h1, h2, h3, h4, h5, h6')
    if (heading && heading.id) {
      this.modalTarget.setAttribute('aria-labelledby', heading.id)
    }
    
    // If modal has a description, set aria-describedby
    const description = this.modalTarget.querySelector('[data-description]')
    if (description && description.id) {
      this.modalTarget.setAttribute('aria-describedby', description.id)
    }
  }

  // Open modal with accessibility features
  openModal() {
    if (!this.hasModalTarget) return
    
    // Show the modal
    this.modalTarget.classList.remove('hidden')
    
    // Activate focus trap
    this.activateFocusTrap()
    
    // Announce to screen readers
    this.announce('Dialog opened')
    
    // Prevent background scrolling
    document.body.style.overflow = 'hidden'
  }

  // Close modal with accessibility features
  closeModal() {
    if (!this.hasModalTarget) return
    
    // Hide the modal
    this.modalTarget.classList.add('hidden')
    
    // Deactivate focus trap
    this.deactivateFocusTrap()
    
    // Announce to screen readers
    this.announce('Dialog closed')
    
    // Restore background scrolling
    document.body.style.overflow = ''
  }

  // Make an announcement for screen readers
  announce(message, politeness = 'polite') {
    if (!this.hasAnnouncementTarget) {
      // Create an announcement element if it doesn't exist
      const announcement = document.createElement('div')
      announcement.setAttribute('data-accessibility-target', 'announcement')
      announcement.setAttribute('aria-live', politeness)
      announcement.setAttribute('aria-atomic', 'true')
      announcement.classList.add('sr-only')
      document.body.appendChild(announcement)
      this.announcementTarget = announcement
    }
    
    // Set the message
    this.announcementTarget.textContent = message
    
    // Clear the message after a delay
    setTimeout(() => {
      this.announcementTarget.textContent = ''
    }, 3000)
  }

  // Focus a specific element
  focusElement(event) {
    const elementId = event.params.id
    if (!elementId) return
    
    const element = document.getElementById(elementId)
    if (element) {
      element.focus()
    }
  }

  // Toggle high contrast mode
  toggleHighContrast() {
    const isHighContrast = document.documentElement.classList.toggle('high-contrast')
    
    // Save preference to localStorage
    localStorage.setItem('highContrast', isHighContrast)
    
    // Dispatch custom event
    document.dispatchEvent(new CustomEvent('highContrastChanged', {
      detail: { enabled: isHighContrast }
    }))
    
    // Announce to screen readers
    this.announce(`High contrast mode ${isHighContrast ? 'enabled' : 'disabled'}`)
  }

  // Toggle reduce motion
  toggleReduceMotion() {
    const isReduceMotion = document.documentElement.classList.toggle('reduce-motion')
    
    // Save preference to localStorage
    localStorage.setItem('reduceMotion', isReduceMotion)
    
    // Dispatch custom event
    document.dispatchEvent(new CustomEvent('reduceMotionChanged', {
      detail: { enabled: isReduceMotion }
    }))
    
    // Announce to screen readers
    this.announce(`Reduced motion ${isReduceMotion ? 'enabled' : 'disabled'}`)
  }

  // Change text size
  changeTextSize(event) {
    const size = event.params.size || '3'
    
    // Remove existing text size classes
    document.documentElement.classList.remove('text-size-1', 'text-size-2', 'text-size-3', 'text-size-4', 'text-size-5')
    
    // Add new text size class
    document.documentElement.classList.add(`text-size-${size}`)
    
    // Save preference to localStorage
    localStorage.setItem('textSize', size)
    
    // Dispatch custom event
    document.dispatchEvent(new CustomEvent('textSizeChanged', {
      detail: { size }
    }))
    
    // Announce to screen readers
    this.announce(`Text size changed to level ${size}`)
  }
}
