import { Controller } from "@hotwired/stimulus"

// This is a debug controller to help troubleshoot theme issues
export default class extends Controller {
  connect() {
    console.log("Debug controller connected")
    this.logThemeState()
    
    // Listen for theme changes
    document.addEventListener('theme-changed', () => {
      setTimeout(() => this.logThemeState(), 100)
    })
  }
  
  logThemeState() {
    const isDark = document.documentElement.classList.contains('dark')
    const storedTheme = localStorage.getItem('theme')
    const systemPrefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches
    
    // Get computed colors to verify CSS variables are working
    const bodyBgColor = getComputedStyle(document.body).backgroundColor
    const textColor = getComputedStyle(document.body).color
    
    console.log('Theme Debug:', {
      'dark class applied': isDark,
      'localStorage theme': storedTheme,
      'system prefers dark': systemPrefersDark,
      'body background': bodyBgColor,
      'text color': textColor
    })
  }
}