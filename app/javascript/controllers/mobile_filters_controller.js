import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar", "overlay"]

  connect() {
    // Initialize the controller
  }

  show() {
    // Show the sidebar with animation
    this.sidebarTarget.classList.remove("-translate-x-full")
    this.overlayTarget.classList.remove("hidden")
    
    // Prevent scrolling of the body
    document.body.style.overflow = "hidden"
  }

  hide() {
    // Hide the sidebar with animation
    this.sidebarTarget.classList.add("-translate-x-full")
    this.overlayTarget.classList.add("hidden")
    
    // Restore scrolling
    document.body.style.overflow = ""
  }

  // Close the sidebar when clicking outside of it
  clickOutside(event) {
    if (event.target === this.overlayTarget) {
      this.hide()
    }
  }
}
