import { Controller } from "@hotwired/stimulus"


export default class extends Controller {
  static targets = ["lightIcon", "darkIcon"]
  
  connect() {
    // Initialize theme based on localStorage or system preference
    this.initializeTheme()
    
    // Update icon visibility
    this.updateIcons()
  }
  
  /**
   * Set the initial theme based on localStorage or system preference
   */
  initializeTheme() {
    // Check if theme is stored in localStorage
    const storedTheme = localStorage.getItem('theme')
    
    if (storedTheme === 'dark') {
      document.documentElement.classList.add('dark')
    } else if (storedTheme === 'light') {
      document.documentElement.classList.remove('dark')
    } else {
      // If no theme is stored, check system preference
      if (window.matchMedia('(prefers-color-scheme: dark)').matches) {
        document.documentElement.classList.add('dark')
        localStorage.setItem('theme', 'dark')
      } else {
        document.documentElement.classList.remove('dark')
        localStorage.setItem('theme', 'light')
      }
    }
  }
  
  /**
   * Toggle between light and dark mode
   */
  toggle() {
    const isDark = document.documentElement.classList.contains('dark')
    
    if (isDark) {
      document.documentElement.classList.remove('dark')
      localStorage.setItem('theme', 'light')
    } else {
      document.documentElement.classList.add('dark')
      localStorage.setItem('theme', 'dark')
    }
    
    this.updateIcons()
  }
  
  /**
   * Update the visibility of theme icons based on current theme
   */
  updateIcons() {
    if (!this.hasLightIconTarget || !this.hasDarkIconTarget) {
      return
    }
    
    const isDark = document.documentElement.classList.contains('dark')
    
    if (isDark) {
      this.lightIconTarget.classList.remove('hidden')
      this.darkIconTarget.classList.add('hidden')
    } else {
      this.lightIconTarget.classList.add('hidden')
      this.darkIconTarget.classList.remove('hidden')
    }
  }
}