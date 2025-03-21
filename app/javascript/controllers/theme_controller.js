import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="theme"
export default class extends Controller {
  static targets = ["lightIcon", "darkIcon"]

  connect() {
    console.log("Theme controller connected")
    // Force immediate update with a slight delay to ensure targets are accessible
    setTimeout(() => {
      this.updateTheme()
    }, 50)
    
    // Listen for system preference changes
    window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', () => {
      if (localStorage.getItem("theme") === "system" || !localStorage.getItem("theme")) {
        this.updateTheme()
      }
    })
    
    // Update when theme changes elsewhere in the app
    document.addEventListener('theme-changed', () => this.updateTheme())
  }

  setMode(event) {
    const mode = event.currentTarget.dataset.themeParam
    localStorage.setItem("theme", mode)
    this.updateTheme()
  }
  
  toggle() {
    const isDark = document.documentElement.classList.contains("dark")
    const newTheme = isDark ? "light" : "dark"
    localStorage.setItem("theme", newTheme)
    this.updateTheme()
    
    // Dispatch event for other components to respond to
    document.dispatchEvent(new CustomEvent('theme-changed', { 
      detail: { theme: newTheme },
      bubbles: true
    }))
  }
  
  updateTheme() {
    const savedTheme = localStorage.getItem("theme")
    const systemPrefersDark = window.matchMedia("(prefers-color-scheme: dark)").matches
    
    // Determine if dark mode should be active
    const isDark = savedTheme === "dark" || 
                 (savedTheme === "system" && systemPrefersDark) || 
                 (!savedTheme && systemPrefersDark)
    
    // Apply theme based on preference or system default
    if (isDark) {
      document.documentElement.classList.add("dark")
      document.documentElement.classList.remove("light")
    } else {
      document.documentElement.classList.remove("dark")
      document.documentElement.classList.add("light")
    }
    
    // Update any UI indicators if they exist
    if (this.hasLightIconTarget && this.hasDarkIconTarget) {
      this.lightIconTarget.classList.toggle("hidden", !isDark)
      this.darkIconTarget.classList.toggle("hidden", isDark)
    }
    
    // Update theme indicator if it exists
    const themeIndicator = document.getElementById('theme-indicator')
    if (themeIndicator) {
      themeIndicator.textContent = isDark ? 'dark' : 'light'
    }
    
    console.log('Theme updated:', isDark ? 'dark' : 'light')
  }
}
