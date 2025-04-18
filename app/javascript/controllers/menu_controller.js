import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "button", "content", "iconMenu", "iconClose" ]

  connect() {
    // Ensure the menu is closed initially
    if (this.hasContentTarget) {
      this.contentTarget.classList.add("hidden");
    }

    if (this.hasIconMenuTarget && this.hasIconCloseTarget) {
      this.iconMenuTarget.classList.remove("hidden");
      this.iconCloseTarget.classList.add("hidden");
    }

    // Close menu when clicking outside - use a bound function to maintain context
    this._clickOutsideHandler = this.closeMenuOnClickOutside.bind(this);
    document.addEventListener("click", this._clickOutsideHandler);
  }

  disconnect() {
    // Use the same bound function when removing event listener
    document.removeEventListener("click", this._clickOutsideHandler);
  }

  toggle(event) {
    // Prevent default behavior
    if (event) {
      event.preventDefault();
      event.stopPropagation();
    }

    if (!this.hasContentTarget) return;

    // Check if the menu is currently open
    const isOpen = !this.contentTarget.classList.contains("hidden");

    if (isOpen) {
      this.close();
    } else {
      this.open();
    }
  }

  open() {
    if (!this.hasContentTarget) return;

    // Show the menu
    this.contentTarget.classList.remove("hidden");

    // Toggle icons
    if (this.hasIconMenuTarget && this.hasIconCloseTarget) {
      this.iconMenuTarget.classList.add("hidden");
      this.iconCloseTarget.classList.remove("hidden");
    }

    // Add animation
    this.contentTarget.classList.add("animate-slideDown");
    setTimeout(() => {
      this.contentTarget.classList.remove("animate-slideDown");
    }, 300);
  }

  close() {
    if (!this.hasContentTarget) return;

    // Hide the menu
    this.contentTarget.classList.add("hidden");

    // Toggle icons
    if (this.hasIconMenuTarget && this.hasIconCloseTarget) {
      this.iconMenuTarget.classList.remove("hidden");
      this.iconCloseTarget.classList.add("hidden");
    }
  }

  closeMenuOnClickOutside(event) {
    if (!this.hasButtonTarget || !this.hasContentTarget) return;

    // Don't close if clicking on the button (the toggle method will handle this)
    if (this.buttonTarget.contains(event.target)) {
      return;
    }

    // Don't close if clicking inside the menu
    if (this.contentTarget.contains(event.target)) {
      return;
    }

    // Only close if the menu is currently open
    if (!this.contentTarget.classList.contains("hidden")) {
      this.close();
    }
  }
}