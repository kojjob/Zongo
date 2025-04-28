import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["backdrop", "content"]
  
  static values = {
    type: { type: String, default: "default" }
  }
  
  connect() {
    // Apply color based on type
    this.applyColorClasses()
  }
  
  applyColorClasses() {
    // Apply different colors based on the alert type
    // Implementation would be similar to the class handling in the ERB template
  }
  
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
    
    // Focus confirm button if present, otherwise first focusable element
    setTimeout(() => {
      this.focusPrimaryButton()
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
      
      // Disable scroll lock
      document.body.style.overflow = ""
      document.body.style.paddingRight = ""
    }, 300)
  }
  
  confirm(event) {
    event.preventDefault()
    
    // Dispatch a custom event that can be listened for
    const confirmEvent = new CustomEvent("alert-dialog:confirm", {
      bubbles: true,
      detail: { dialog: this.element, type: this.typeValue }
    })
    
    this.element.dispatchEvent(confirmEvent)
    this.close()
  }
  
  cancel(event) {
    event.preventDefault()
    
    // Dispatch a custom event
    const cancelEvent = new CustomEvent("alert-dialog:cancel", {
      bubbles: true,
      detail: { dialog: this.element, type: this.typeValue }
    })
    
    this.element.dispatchEvent(cancelEvent)
    this.close()
  }
  
  handleKeydown(event) {
    if (event.key === "Escape") {
      this.close(event)
    }
    
    // Handle Tab key for focus trap
    if (event.key === "Tab") {
      this.handleTabKey(event)
    }
    
    // Handle Enter key to confirm
    if (event.key === "Enter" && !event.isComposing) {
      const primaryButton = this.element.querySelector("[data-alert-dialog-primary-button]")
      if (primaryButton) {
        primaryButton.click()
      }
    }
  }
  
  handleBackdropClick(event) {
    if (event.target === this.backdropTarget) {
      this.close(event)
    }
  }
  
  handleTabKey(event) {
    // Same implementation as in the modal controller
    const focusableElements = Array.from(
      this.contentTarget.querySelectorAll('button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])')
    ).filter(el => !el.disabled && el.offsetWidth > 0 && el.offsetHeight > 0)
    
    if (focusableElements.length === 0) return
    
    const firstElement = focusableElements[0]
    const lastElement = focusableElements[focusableElements.length - 1]
    
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
  
  focusPrimaryButton() {
    // Focus the primary button if present
    const primaryButton = this.element.querySelector("[data-alert-dialog-primary-button]")
    if (primaryButton) {
      primaryButton.focus()
    } else {
      this.focusFirstElement()
    }
  }
  
  focusFirstElement() {
    const focusableElements = Array.from(
      this.contentTarget.querySelectorAll('button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])')
    ).filter(el => !el.disabled && el.offsetWidth > 0 && el.offsetHeight > 0)
    
    if (focusableElements.length > 0) {
      focusableElements[0].focus()
    }
  }
  
  getScrollbarWidth() {
    return window.innerWidth - document.documentElement.clientWidth
  }
}
