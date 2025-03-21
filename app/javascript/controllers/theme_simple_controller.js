import { Controller } from "@hotwired/stimulus"

// Simplified theme controller - basic functionality only
export default class extends Controller {
  static targets = ["lightIcon", "darkIcon"]

  connect() {
    console.log("Theme Simple controller connected!")
    this.updateIcons()
  }

  toggle() {
    console.log("Toggling theme...")
    // Get the current theme
    const isDark = document.documentElement.classList.contains("dark")
    
    // Toggle the theme
    if (isDark) {
      document.documentElement.classList.remove("dark")
      document.documentElement.classList.add("light")
      localStorage.setItem("theme", "light")
    } else {
      document.documentElement.classList.add("dark")
      document.documentElement.classList.remove("light")
      localStorage.setItem("theme", "dark")
    }
    
    // Update icons
    this.updateIcons()
    
    console.log("Theme toggled to:", isDark ? "light" : "dark")
  }
  
  updateIcons() {
    // Skip if we don't have both icon targets
    if (!this.hasLightIconTarget || !this.hasDarkIconTarget) {
      console.log("Missing icon targets")
      return
    }
    
    const isDark = document.documentElement.classList.contains("dark")
    
    // Update icon visibility
    this.lightIconTarget.classList.toggle("hidden", !isDark)
    this.darkIconTarget.classList.toggle("hidden", isDark)
    
    console.log("Icons updated:", isDark ? "dark mode" : "light mode")
  }
}
