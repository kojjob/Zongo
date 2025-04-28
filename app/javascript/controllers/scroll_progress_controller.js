import { Controller } from "@hotwired/stimulus"

/**
 * Scroll Progress Controller
 * 
 * This controller handles the scroll progress indicator that appears at the top of the page.
 * It shows how far the user has scrolled down the page.
 */
export default class extends Controller {
  connect() {
    // Initialize scroll event listener
    this._handleScroll = this.handleScroll.bind(this)
    window.addEventListener('scroll', this._handleScroll, { passive: true })
    
    // Initial calculation
    this.handleScroll()
  }
  
  disconnect() {
    // Clean up event listener
    window.removeEventListener('scroll', this._handleScroll)
  }
  
  handleScroll() {
    // Calculate scroll progress
    const windowHeight = window.innerHeight
    const documentHeight = document.documentElement.scrollHeight
    const scrollTop = window.scrollY || document.documentElement.scrollTop
    
    // Only show progress if page is scrollable
    if (documentHeight <= windowHeight) {
      this.element.style.width = '0%'
      this.element.style.opacity = '0'
      return
    }
    
    // Calculate percentage scrolled
    const scrolled = (scrollTop / (documentHeight - windowHeight)) * 100
    
    // Update progress bar width
    this.element.style.width = `${scrolled}%`
    
    // Show/hide based on scroll position
    if (scrollTop > 100) {
      this.element.style.opacity = '1'
    } else {
      this.element.style.opacity = '0'
    }
  }
}
