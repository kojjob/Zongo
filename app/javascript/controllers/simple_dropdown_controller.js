import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  toggle(event) {
    if (event) {
      event.preventDefault();
      event.stopPropagation();
    }

    if (this.hasMenuTarget) {
      this.menuTarget.classList.toggle("hidden");

      // Toggle the dropdown arrow rotation
      const button = event.currentTarget;
      const arrow = button.querySelector('svg');
      if (arrow) {
        arrow.classList.toggle('rotate-180');
      }
    }
  }

  // Close the dropdown when clicking outside
  connect() {
    this.clickOutsideHandler = this.closeOnClickOutside.bind(this);
    document.addEventListener('click', this.clickOutsideHandler);
  }

  disconnect() {
    document.removeEventListener('click', this.clickOutsideHandler);
  }

  closeOnClickOutside(event) {
    if (!this.menuTarget) return;

    // Don't close if clicking on the button or inside the menu
    if (this.element.contains(event.target)) {
      // Only proceed if we're clicking outside the toggle button
      const toggleButton = this.element.querySelector('[data-action*="simple-dropdown#toggle"]');
      if (toggleButton && toggleButton.contains(event.target)) {
        return;
      }

      // If we're clicking inside the menu but not on the button, don't close
      if (this.menuTarget.contains(event.target)) {
        return;
      }
    }

    // Close the dropdown and reset the arrow
    if (!this.menuTarget.classList.contains('hidden')) {
      this.menuTarget.classList.add('hidden');

      // Reset all dropdown arrows
      const button = this.element.querySelector('[data-action*="simple-dropdown#toggle"]');
      if (button) {
        const arrow = button.querySelector('svg');
        if (arrow) {
          arrow.classList.remove('rotate-180');
        }
      }
    }
  }
}
