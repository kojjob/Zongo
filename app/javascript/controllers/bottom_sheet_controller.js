import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["backdrop", "content", "dragHandle"]
  
  connect() {
    this.startY = 0
    this.currentY = 0
    this.dragging = false
  }
  
  open() {
    this.element.classList.remove("hidden")
    
    // Enable scroll lock
    document.body.style.overflow = "hidden"
    
    // Trigger animations with a slight delay for proper rendering
    setTimeout(() => {
      this.backdropTarget.classList.remove("opacity-0")
      this.contentTarget.classList.remove("translate-y-full")
      this.contentTarget.classList.add("translate-y-0")
    }, 10)
  }
  
  close(event) {
    if (event) event.preventDefault()
    
    this.backdropTarget.classList.add("opacity-0")
    this.contentTarget.classList.remove("translate-y-0")
    this.contentTarget.classList.add("translate-y-full")
    
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
  
  handleBackdropClick(event) {
    if (event.target === this.backdropTarget) {
      this.close(event)
    }
  }
  
  handleTouchStart(event) {
    if (event.target === this.dragHandleTarget || this.dragHandleTarget.contains(event.target)) {
      this.startY = event.touches[0].clientY
      this.currentY = this.startY
      this.dragging = true
    }
  }
  
  handleTouchMove(event) {
    if (!this.dragging) return
    
    this.currentY = event.touches[0].clientY
    const deltaY = this.currentY - this.startY
    
    if (deltaY > 0) {
      // Only allow dragging down
      this.contentTarget.style.transform = `translateY(${deltaY}px)`
    }
  }
  
  handleTouchEnd(event) {
    if (!this.dragging) return
    
    this.dragging = false
    const deltaY = this.currentY - this.startY
    
    if (deltaY > 100) {
      // If dragged down more than 100px, close the sheet
      this.close()
    } else {
      // Otherwise, snap back to open position
      this.contentTarget.style.transform = ""
    }
  }
}
