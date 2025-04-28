  import { Controller } from "@hotwired/stimulus"

  export default class extends Controller {
    static targets = ["container", "backdrop", "content"]
    
    static values = {
      allowClose: { type: Boolean, default: true }
    }
    
    connect() {
      this.enableScrollLock()
    }
    
    disconnect() {
      this.disableScrollLock()
    }
    
    open() {
      this.element.classList.remove("hidden")
      
      // Trigger animations with a slight delay for proper rendering
      setTimeout(() => {
        this.backdropTarget.classList.remove("opacity-0")
        this.contentTarget.classList.remove("opacity-0", "scale-90")
        this.contentTarget.classList.add("opacity-100", "scale-100")
      }, 10)
      
      this.enableScrollLock()
      this.announceOpen()
      
      // Set focus to first focusable element
      setTimeout(() => {
        this.focusFirstElement()
      }, 300)
    }
    
    close(event) {
      if (event) event.preventDefault()
      
      this.backdropTarget.classList.add("opacity-0")
      this.contentTarget.classList.remove("opacity-100", "scale-100")
      this.contentTarget.classList.add("opacity-0", "scale-90")
      
      // Hide after animation completes
      setTimeout(() => {
        this.element.classList.add("hidden")
        this.disableScrollLock()
        this.announceClose()
      }, 300)
    }
    
    handleKeydown(event) {
      if (event.key === "Escape" && this.allowCloseValue) {
        this.close(event)
      }
      
      // Handle Tab key for focus trap
      if (event.key === "Tab") {
        this.handleTabKey(event)
      }
    }
    
    handleBackdropClick(event) {
      if (this.allowCloseValue && event.target === this.backdropTarget) {
        this.close(event)
      }
    }
    
    handleTabKey(event) {
      // Get all focusable elements within the modal
      const focusableElements = Array.from(
        this.contentTarget.querySelectorAll('button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])')
      ).filter(el => !el.disabled && el.offsetWidth > 0 && el.offsetHeight > 0)
      
      if (focusableElements.length === 0) return
      
      const firstElement = focusableElements[0]
      const lastElement = focusableElements[focusableElements.length - 1]
      
      // Handle Tab key for focus trap
      if (event.shiftKey) {
        if (document.activeElement === firstElement) {
          lastElement.focus()
          event.preventDefault()
        }
      } else {
        if (document.activeElement === lastElement) {
          firstElement.focus()
          event.preventDefault()
        }
      }
    }
    
    focusFirstElement() {
      // Get all focusable elements within the modal
      const focusableElements = Array.from(
        this.contentTarget.querySelectorAll('button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])')
      ).filter(el => !el.disabled && el.offsetWidth > 0 && el.offsetHeight > 0)
      
      if (focusableElements.length > 0) {
        focusableElements[0].focus()
      }
    }
    
    enableScrollLock() {
      document.body.style.overflow = "hidden"
      document.body.style.paddingRight = this.getScrollbarWidth() + "px"
    }
    
    disableScrollLock() {
      document.body.style.overflow = ""
      document.body.style.paddingRight = ""
    }
    
    getScrollbarWidth() {
      return window.innerWidth - document.documentElement.clientWidth
    }
    
    announceOpen() {
      // For screen readers
      const announcer = document.getElementById("announcer")
      if (announcer) {
        announcer.textContent = "Dialog opened."
      }
    }
    
    announceClose() {
      // For screen readers
      const announcer = document.getElementById("announcer")
      if (announcer) {
        announcer.textContent = "Dialog closed."
      }
    }
  }