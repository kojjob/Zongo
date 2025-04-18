import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "menu"]

  connect() {
    // Make sure the dropdown is closed initially
    if (this.hasMenuTarget) {
      this.menuTarget.classList.add("hidden");
    }

    // Set up event listeners
    this._clickOutsideHandler = this._handleClickOutside.bind(this);
    document.addEventListener("click", this._clickOutsideHandler);
  }

  disconnect() {
    // Clean up event listeners
    document.removeEventListener("click", this._clickOutsideHandler);
  }

  toggle(event) {
    if (event) {
      event.preventDefault();
      event.stopPropagation();
    }

    if (!this.hasMenuTarget) return;

    // Toggle the hidden class
    const isHidden = this.menuTarget.classList.contains("hidden");

    if (isHidden) {
      // Show the dropdown
      this.menuTarget.classList.remove("hidden");

      // Update button state for styling
      if (this.hasButtonTarget) {
        this.buttonTarget.setAttribute("data-dropdown-open", "");
      }
    } else {
      // Hide the dropdown
      this.menuTarget.classList.add("hidden");

      // Update button state for styling
      if (this.hasButtonTarget) {
        this.buttonTarget.removeAttribute("data-dropdown-open");
      }
    }
  }

  _handleClickOutside(event) {
    if (!this.hasMenuTarget || !this.hasButtonTarget) return;

    // Don't close if clicking on the button or inside the menu
    if (this.buttonTarget.contains(event.target) || this.menuTarget.contains(event.target)) {
      return;
    }

    // Close the dropdown if it's open
    if (!this.menuTarget.classList.contains("hidden")) {
      this.menuTarget.classList.add("hidden");

      // Update button state for styling
      if (this.hasButtonTarget) {
        this.buttonTarget.removeAttribute("data-dropdown-open");
      }
    }
  }
}
