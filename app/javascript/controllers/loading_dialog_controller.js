import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["backdrop", "content", "progressBar", "progressText"]
  
  open() {
    this.element.classList.remove("hidden")
    
    // Enable scroll lock
    document.body.style.overflow = "hidden"
    document.body.style.paddingRight = this.getScrollbarWidth() + "px"
    
    // Trigger animations with a slight delay for proper rendering
    setTimeout(() => {
      this.backdropTarget.classList.remove("opacity-0")
      this.contentTarget.classList.remove("opacity-0", "scale-90")
      this.contentTarget.classList.add("opacity-100", "scale-100")
    }, 10)
  }
  
  close(event) {
    if (event) event.preventDefault()
    
    this.backdropTarget.classList.add("opacity-0")
    this.contentTarget.classList.remove("opacity-100", "scale-100")
    this.contentTarget.classList.add("opacity-0", "scale-90")
    
    // Hide after animation completes
    setTimeout(() => {
      this.element.classList.add("hidden")
      
      // Disable scroll lock
      document.body.style.overflow = ""
      document.body.style.paddingRight = ""
      
      // Reset progress if needed
      if (this.hasProgressBarTarget) {
        this.progressBarTarget.style.width = "0%"
        this.progressTextTarget.textContent = "0%"
      }
    }, 300)
  }
  
  updateProgress(value) {
    if (!this.hasProgressBarTarget) return
    
    const progress = Math.min(Math.max(value, 0), 100)
    this.progressBarTarget.style.width = `${progress}%`
    this.progressTextTarget.textContent = `${Math.round(progress)}%`
  }
  
  getScrollbarWidth() {
    return window.innerWidth - document.documentElement.clientWidth
  }
}