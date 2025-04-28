import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container"]
  
  open() {
    this.element.classList.remove("hidden")
    
    // Enable scroll lock (but the modal itself can scroll)
    document.body.style.overflow = "hidden"
    
    // Trigger animations with a slight delay for proper rendering
    setTimeout(() => {
      this.containerTarget.classList.remove("opacity-0")
      this.containerTarget.classList.add("opacity-100")
    }, 10)
  }
  
  close(event) {
    if (event) event.preventDefault()
    
    this.containerTarget.classList.remove("opacity-100")
    this.containerTarget.classList.add("opacity-0")
    
    // Hide after animation completes
    setTimeout(() => {
      this.element.classList.add("hidden")
      
      // Disable scroll lock
      document.body.style.overflow = ""
    }, 300)
  }
  
  handleKeydown(event) {
    if (event.key === "Escape") {
      this.close(event)
    }
  }
}
