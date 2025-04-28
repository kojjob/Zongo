import { Controller } from "@hotwired/stimulus"

/**
 * Calendar Dropdown Controller
 * Manages the calendar integration dropdown menu for event pages
 */
export default class extends Controller {
  static targets = ["menu", "notification", "notificationMessage"]

  /**
   * Toggle the calendar dropdown menu
   */
  toggle() {
    this.menuTarget.classList.toggle("opacity-0")
    this.menuTarget.classList.toggle("scale-95")
    this.menuTarget.classList.toggle("pointer-events-none")
    this.menuTarget.classList.toggle("hidden")
  }

  /**
   * Hide the calendar dropdown when clicking outside
   */
  hide(event) {
    if (!this.element.contains(event.target)) {
      this.menuTarget.classList.add("opacity-0", "scale-95", "pointer-events-none", "hidden")
    }
  }

  /**
   * Handle calendar selection and show feedback notification
   * @param {Event} event - The click event
   */
  selected(event) {
    // Hide the dropdown menu
    this.menuTarget.classList.add("opacity-0", "scale-95", "pointer-events-none", "hidden")

    // Update notification message
    const calendarService = event.currentTarget.dataset.calendarService
    this.notificationMessageTarget.textContent = `Opening event in ${calendarService}`

    // Show notification
    this.notificationTarget.classList.remove("opacity-0", "scale-95", "pointer-events-none", "hidden")

    // Hide notification after 3 seconds
    setTimeout(() => {
      this.notificationTarget.classList.add("opacity-0", "scale-95", "pointer-events-none", "hidden")
    }, 3000)
  }
}
