 import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["backdrop", "content"]
  
  static values = {
    position: { type: String, default: "right" },
    width: { type: String, default: "md" }
  }
  
  connect() {
    this.setupInitialPosition()
    this.applyWidth()
  }
  
  setupInitialPosition() {
    // Position the dialog based on the position value
    const contentEl = this.contentTarget
    
    if (this.positionValue === "left") {
      contentEl.classList.remove("right-0", "translate-x-full")
      contentEl.classList.add("left-0", "-translate-x-full")
    } else {
      contentEl.classList.remove("left-0", "-translate-x-full")
      contentEl.classList.add("right-0", "translate-x-full")
    }
  }
  
  applyWidth() {
    // Apply width class based on the width value
    const widthClass = this.getWidthClass()
    this.contentTarget.classList.add(widthClass)
  }
  
  getWidthClass() {
    switch (this.widthValue) {
      case "sm": return "max-w-sm"
      case "md": return "max-w-md"
      case "lg": return "max-w-lg"
      case "xl": return "max-w-xl"
      case "2xl": return "max-w-2xl"
      case "3xl": return "max-w-3xl"
      case "4xl": return "max-w-4xl"
      case "5xl": return "max-w-5xl"
      case "6xl": return "max-w-6xl"
      case "7xl": return "max-w-7xl"
      case "full": return "max-w-full"
      default: return "max-w-md"
    }
  }
  
  open() {
    this.element.classList.remove("hidden")
    
    // Enable scroll lock
    document.body.style.overflow = "hidden"
    document.body.style.paddingRight = this.getScrollbarWidth() + "px"
    
    // Trigger animations with a slight delay for proper rendering
    setTimeout(() => {
      this.backdropTarget.classList.remove("opacity-0")
      this.contentTarget.classList.remove("opacity-0")
      this.contentTarget.classList.remove(
        this.positionValue === "left" ? "-translate-x-full" : "translate-x-full"
      )
      this.contentTarget.classList.add("translate-x-0")
    }, 10)
    
    // Set focus to first focusable element
    setTimeout(() => {
      this.focusFirstElement()
    }, 300)
  }
  
  close(event) {
    if (event) event.preventDefault()
    
    this.backdropTarget.classList.add("opacity-0")
    this.contentTarget.classList.remove("translate-x-0")
    this.contentTarget.classList.add(
      this.positionValue === "left" ? "-translate-x-full" : "translate-x-full"
    )
    this.contentTarget.classList.add("opacity-0")
    
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
    const confirmEvent = new CustomEvent("slide-dialog:confirm", {
      bubbles: true,
      detail: { dialog: this.element }
    })
    
    this.element.dispatchEvent(confirmEvent)
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

