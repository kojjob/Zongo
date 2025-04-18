import { Controller } from "@hotwired/stimulus"

// Simplified theme controller for header toggle
export default class extends Controller {
  static targets = ["lightIcon", "darkIcon"]

  connect() {
    // Initialize the theme on connect
    this.initializeTheme();
    // Update icons to reflect current theme
    this.updateIcons();
  }

  initializeTheme() {
    // Check for theme in localStorage
    const storedTheme = localStorage.getItem("theme");
    
    // Apply theme based on storage or system preference
    if (storedTheme === "dark") {
      document.documentElement.classList.add("dark");
    } else if (storedTheme === "light") {
      document.documentElement.classList.remove("dark");
    } else {
      // Use system preference if no stored theme
      if (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches) {
        document.documentElement.classList.add("dark");
        localStorage.setItem("theme", "dark");
      } else {
        document.documentElement.classList.remove("dark");
        localStorage.setItem("theme", "light");
      }
    }
  }

  toggle(event) {
    event.preventDefault();
    
    // Get the current theme
    const isDark = document.documentElement.classList.contains("dark");
    
    // Toggle the theme
    if (isDark) {
      document.documentElement.classList.remove("dark");
      localStorage.setItem("theme", "light");
    } else {
      document.documentElement.classList.add("dark");
      localStorage.setItem("theme", "dark");
    }
    
    // Update icons
    this.updateIcons();
    
    // Dispatch theme change event for other components
    this.dispatchThemeChangeEvent();
  }
  
  updateIcons() {
    // Skip if we don't have both icon targets
    if (!this.hasLightIconTarget || !this.hasDarkIconTarget) {
      return;
    }
    
    const isDark = document.documentElement.classList.contains("dark");
    
    // Update icon visibility
    if (isDark) {
      this.lightIconTarget.classList.remove("hidden");
      this.darkIconTarget.classList.add("hidden");
    } else {
      this.lightIconTarget.classList.add("hidden");
      this.darkIconTarget.classList.remove("hidden");
    }
  }
  
  dispatchThemeChangeEvent() {
    const event = new CustomEvent("theme:changed", {
      detail: { theme: document.documentElement.classList.contains("dark") ? "dark" : "light" },
      bubbles: true
    });
    document.dispatchEvent(event);
  }
}
