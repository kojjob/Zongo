import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["lightIcon", "darkIcon", "themeToggle"]
  
  connect() {
    this.updateTheme()
    
    // Check for saved theme preference or respect OS preference
    if (localStorage.theme === 'dark' || 
        (!('theme' in localStorage) && 
         window.matchMedia('(prefers-color-scheme: dark)').matches)) {
      this.enableDarkMode()
    } else {
      this.enableLightMode()
    }
  }
  
  toggle() {
    if (document.documentElement.classList.contains('dark')) {
      this.enableLightMode()
    } else {
      this.enableDarkMode()
    }
  }
  
  enableDarkMode() {
    document.documentElement.classList.add('dark')
    localStorage.theme = 'dark'
    this.updateTheme()
  }
  
  enableLightMode() {
    document.documentElement.classList.remove('dark')
    localStorage.theme = 'light'
    this.updateTheme()
  }
  
  updateTheme() {
    const isDarkMode = document.documentElement.classList.contains('dark')
    
    if (this.hasLightIconTarget && this.hasDarkIconTarget) {
      this.lightIconTarget.classList.toggle('hidden', !isDarkMode)
      this.darkIconTarget.classList.toggle('hidden', isDarkMode)
    }
    
    if (this.hasThemeToggleTarget) {
      this.themeToggleTarget.checked = isDarkMode
    }
  }
}