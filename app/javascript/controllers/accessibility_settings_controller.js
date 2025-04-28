import { Controller } from "@hotwired/stimulus"

/**
 * Accessibility Settings Controller
 * 
 * This controller manages the accessibility settings panel and applies user preferences.
 * It handles:
 * - High contrast mode
 * - Reduced motion
 * - Text size
 * - Focus indicator style
 * - Saving preferences to localStorage
 */
export default class extends Controller {
  static targets = [
    "panel",
    "highContrastToggle",
    "highContrastToggleKnob",
    "reducedMotionToggle",
    "reducedMotionToggleKnob",
    "textSizeSlider",
    "focusStyleSelect"
  ]
  
  connect() {
    // Load saved preferences
    this.loadPreferences()
    
    // Listen for system preference changes
    this.setupMediaQueryListeners()
    
    // Handle escape key to close panel
    this.handleEscapeKey = this.handleEscapeKey.bind(this)
    document.addEventListener('keydown', this.handleEscapeKey)
    
    // Handle click outside to close panel
    this.handleClickOutside = this.handleClickOutside.bind(this)
    document.addEventListener('click', this.handleClickOutside)
  }
  
  disconnect() {
    // Clean up event listeners
    document.removeEventListener('keydown', this.handleEscapeKey)
    document.removeEventListener('click', this.handleClickOutside)
    
    // Clean up media query listeners
    if (this.prefersReducedMotionMediaQuery) {
      this.prefersReducedMotionMediaQuery.removeEventListener('change', this.handleReducedMotionChange)
    }
    
    if (this.prefersHighContrastMediaQuery) {
      this.prefersHighContrastMediaQuery.removeEventListener('change', this.handleHighContrastChange)
    }
  }
  
  // Toggle the accessibility settings panel
  togglePanel(event) {
    event.stopPropagation()
    this.panelTarget.classList.toggle('hidden')
    
    // Set focus to the panel when opened
    if (!this.panelTarget.classList.contains('hidden')) {
      this.panelTarget.focus()
      
      // Announce to screen readers
      this.announce('Accessibility settings panel opened')
    } else {
      // Announce to screen readers
      this.announce('Accessibility settings panel closed')
    }
  }
  
  // Toggle high contrast mode
  toggleHighContrast() {
    const isHighContrast = document.documentElement.classList.toggle('high-contrast')
    
    // Update toggle state
    this.highContrastToggleTarget.setAttribute('aria-checked', isHighContrast)
    this.highContrastToggleKnobTarget.classList.toggle('translate-x-6', isHighContrast)
    this.highContrastToggleKnobTarget.classList.toggle('translate-x-1', !isHighContrast)
    
    // Save preference
    localStorage.setItem('highContrast', isHighContrast)
    
    // Announce to screen readers
    this.announce(`High contrast mode ${isHighContrast ? 'enabled' : 'disabled'}`)
  }
  
  // Toggle reduced motion
  toggleReducedMotion() {
    const isReducedMotion = document.documentElement.classList.toggle('reduce-motion')
    
    // Update toggle state
    this.reducedMotionToggleTarget.setAttribute('aria-checked', isReducedMotion)
    this.reducedMotionToggleKnobTarget.classList.toggle('translate-x-6', isReducedMotion)
    this.reducedMotionToggleKnobTarget.classList.toggle('translate-x-1', !isReducedMotion)
    
    // Save preference
    localStorage.setItem('reduceMotion', isReducedMotion)
    
    // Announce to screen readers
    this.announce(`Reduced motion ${isReducedMotion ? 'enabled' : 'disabled'}`)
  }
  
  // Change text size
  changeTextSize() {
    const size = this.textSizeSliderTarget.value
    
    // Remove existing text size classes
    document.documentElement.classList.remove('text-size-1', 'text-size-2', 'text-size-3', 'text-size-4', 'text-size-5')
    
    // Add new text size class
    document.documentElement.classList.add(`text-size-${size}`)
    
    // Save preference
    localStorage.setItem('textSize', size)
    
    // Announce to screen readers
    this.announce(`Text size changed to level ${size}`)
  }
  
  // Change focus indicator style
  changeFocusStyle() {
    const style = this.focusStyleSelectTarget.value
    
    // Remove existing focus style classes
    document.documentElement.classList.remove('focus-default', 'focus-solid', 'focus-dashed', 'focus-dotted', 'focus-thick')
    
    // Add new focus style class
    document.documentElement.classList.add(`focus-${style}`)
    
    // Save preference
    localStorage.setItem('focusStyle', style)
    
    // Announce to screen readers
    this.announce(`Focus indicator style changed to ${style}`)
  }
  
  // Reset all settings to defaults
  resetSettings() {
    // Reset high contrast
    document.documentElement.classList.remove('high-contrast')
    this.highContrastToggleTarget.setAttribute('aria-checked', 'false')
    this.highContrastToggleKnobTarget.classList.remove('translate-x-6')
    this.highContrastToggleKnobTarget.classList.add('translate-x-1')
    
    // Reset reduced motion
    document.documentElement.classList.remove('reduce-motion')
    this.reducedMotionToggleTarget.setAttribute('aria-checked', 'false')
    this.reducedMotionToggleKnobTarget.classList.remove('translate-x-6')
    this.reducedMotionToggleKnobTarget.classList.add('translate-x-1')
    
    // Reset text size
    document.documentElement.classList.remove('text-size-1', 'text-size-2', 'text-size-3', 'text-size-4', 'text-size-5')
    document.documentElement.classList.add('text-size-3')
    this.textSizeSliderTarget.value = 3
    
    // Reset focus style
    document.documentElement.classList.remove('focus-default', 'focus-solid', 'focus-dashed', 'focus-dotted', 'focus-thick')
    document.documentElement.classList.add('focus-default')
    this.focusStyleSelectTarget.value = 'default'
    
    // Clear saved preferences
    localStorage.removeItem('highContrast')
    localStorage.removeItem('reduceMotion')
    localStorage.removeItem('textSize')
    localStorage.removeItem('focusStyle')
    
    // Announce to screen readers
    this.announce('All accessibility settings reset to defaults')
  }
  
  // Load saved preferences
  loadPreferences() {
    // Load high contrast preference
    const highContrast = localStorage.getItem('highContrast') === 'true'
    if (highContrast) {
      document.documentElement.classList.add('high-contrast')
      this.highContrastToggleTarget.setAttribute('aria-checked', 'true')
      this.highContrastToggleKnobTarget.classList.remove('translate-x-1')
      this.highContrastToggleKnobTarget.classList.add('translate-x-6')
    }
    
    // Load reduced motion preference
    const reduceMotion = localStorage.getItem('reduceMotion') === 'true'
    if (reduceMotion) {
      document.documentElement.classList.add('reduce-motion')
      this.reducedMotionToggleTarget.setAttribute('aria-checked', 'true')
      this.reducedMotionToggleKnobTarget.classList.remove('translate-x-1')
      this.reducedMotionToggleKnobTarget.classList.add('translate-x-6')
    }
    
    // Load text size preference
    const textSize = localStorage.getItem('textSize') || '3'
    document.documentElement.classList.add(`text-size-${textSize}`)
    this.textSizeSliderTarget.value = textSize
    
    // Load focus style preference
    const focusStyle = localStorage.getItem('focusStyle') || 'default'
    document.documentElement.classList.add(`focus-${focusStyle}`)
    this.focusStyleSelectTarget.value = focusStyle
    
    // Check system preferences
    this.checkSystemPreferences()
  }
  
  // Check system preferences
  checkSystemPreferences() {
    // Check for prefers-reduced-motion
    if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
      // Only apply if user hasn't explicitly set a preference
      if (localStorage.getItem('reduceMotion') === null) {
        document.documentElement.classList.add('reduce-motion')
        this.reducedMotionToggleTarget.setAttribute('aria-checked', 'true')
        this.reducedMotionToggleKnobTarget.classList.remove('translate-x-1')
        this.reducedMotionToggleKnobTarget.classList.add('translate-x-6')
      }
    }
    
    // Check for prefers-contrast
    if (window.matchMedia('(prefers-contrast: more)').matches) {
      // Only apply if user hasn't explicitly set a preference
      if (localStorage.getItem('highContrast') === null) {
        document.documentElement.classList.add('high-contrast')
        this.highContrastToggleTarget.setAttribute('aria-checked', 'true')
        this.highContrastToggleKnobTarget.classList.remove('translate-x-1')
        this.highContrastToggleKnobTarget.classList.add('translate-x-6')
      }
    }
  }
  
  // Setup media query listeners
  setupMediaQueryListeners() {
    // Listen for prefers-reduced-motion changes
    this.prefersReducedMotionMediaQuery = window.matchMedia('(prefers-reduced-motion: reduce)')
    this.handleReducedMotionChange = (event) => {
      // Only apply if user hasn't explicitly set a preference
      if (localStorage.getItem('reduceMotion') === null) {
        if (event.matches) {
          document.documentElement.classList.add('reduce-motion')
          this.reducedMotionToggleTarget.setAttribute('aria-checked', 'true')
          this.reducedMotionToggleKnobTarget.classList.remove('translate-x-1')
          this.reducedMotionToggleKnobTarget.classList.add('translate-x-6')
        } else {
          document.documentElement.classList.remove('reduce-motion')
          this.reducedMotionToggleTarget.setAttribute('aria-checked', 'false')
          this.reducedMotionToggleKnobTarget.classList.remove('translate-x-6')
          this.reducedMotionToggleKnobTarget.classList.add('translate-x-1')
        }
      }
    }
    this.prefersReducedMotionMediaQuery.addEventListener('change', this.handleReducedMotionChange)
    
    // Listen for prefers-contrast changes
    this.prefersHighContrastMediaQuery = window.matchMedia('(prefers-contrast: more)')
    this.handleHighContrastChange = (event) => {
      // Only apply if user hasn't explicitly set a preference
      if (localStorage.getItem('highContrast') === null) {
        if (event.matches) {
          document.documentElement.classList.add('high-contrast')
          this.highContrastToggleTarget.setAttribute('aria-checked', 'true')
          this.highContrastToggleKnobTarget.classList.remove('translate-x-1')
          this.highContrastToggleKnobTarget.classList.add('translate-x-6')
        } else {
          document.documentElement.classList.remove('high-contrast')
          this.highContrastToggleTarget.setAttribute('aria-checked', 'false')
          this.highContrastToggleKnobTarget.classList.remove('translate-x-6')
          this.highContrastToggleKnobTarget.classList.add('translate-x-1')
        }
      }
    }
    this.prefersHighContrastMediaQuery.addEventListener('change', this.handleHighContrastChange)
  }
  
  // Handle escape key to close panel
  handleEscapeKey(event) {
    if (event.key === 'Escape' && !this.panelTarget.classList.contains('hidden')) {
      this.togglePanel(event)
    }
  }
  
  // Handle click outside to close panel
  handleClickOutside(event) {
    if (!this.panelTarget.classList.contains('hidden') && 
        !this.element.contains(event.target)) {
      this.togglePanel(event)
    }
  }
  
  // Announce message to screen readers
  announce(message, politeness = 'polite') {
    // Create or get the live region
    let liveRegion = document.getElementById('accessibility-live-region')
    if (!liveRegion) {
      liveRegion = document.createElement('div')
      liveRegion.id = 'accessibility-live-region'
      liveRegion.setAttribute('aria-live', politeness)
      liveRegion.setAttribute('aria-atomic', 'true')
      liveRegion.classList.add('sr-only')
      document.body.appendChild(liveRegion)
    }
    
    // Set the message
    liveRegion.textContent = message
    
    // Clear the message after a delay
    setTimeout(() => {
      liveRegion.textContent = ''
    }, 3000)
  }
}
