import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "button", "menu" ]

  connect() {
    // Ensure the dropdown is closed initially
    this.close();

    // Generate a unique ID for this dropdown
    this.id = `dropdown-${Math.random().toString(36).substring(2, 11)}`;

    // Set up event listeners with properly bound methods
    this._clickOutsideHandler = this._handleClickOutside.bind(this);
    this._otherDropdownHandler = this._handleOtherDropdown.bind(this);

    // Add event listeners
    document.addEventListener('click', this._clickOutsideHandler);
    document.addEventListener('dropdown:toggle', this._otherDropdownHandler);
  }

  disconnect() {
    // Clean up event listeners
    document.removeEventListener('click', this._clickOutsideHandler);
    document.removeEventListener('dropdown:toggle', this._otherDropdownHandler);
  }

  toggle(event) {
    // Prevent default behavior
    if (event) {
      event.preventDefault();
      event.stopPropagation();
    }

    // Check if we have the menu target
    if (!this.hasMenuTarget) return;

    // Check if the dropdown is currently open
    const isOpen = !this.menuTarget.classList.contains('opacity-0');

    if (isOpen) {
      // If open, close it
      this.close();
    } else {
      // If closed, open it and notify others
      this.open();

      // Dispatch event to close other dropdowns
      const event = new CustomEvent('dropdown:toggle', {
        bubbles: true,
        detail: { id: this.id }
      });
      document.dispatchEvent(event);
    }
  }

  open() {
    if (!this.hasMenuTarget) return;

    // Position the dropdown correctly
    this._positionDropdown();

    // Show the dropdown
    this.menuTarget.classList.remove('opacity-0', 'scale-95', 'pointer-events-none');
    this.menuTarget.classList.add('opacity-100', 'scale-100');

    // Update button state
    if (this.hasButtonTarget) {
      this.buttonTarget.setAttribute('data-dropdown-open', '');
    }
  }

  close() {
    if (!this.hasMenuTarget) return;

    // Hide the dropdown
    this.menuTarget.classList.remove('opacity-100', 'scale-100');
    this.menuTarget.classList.add('opacity-0', 'scale-95', 'pointer-events-none');

    // Update button state
    if (this.hasButtonTarget) {
      this.buttonTarget.removeAttribute('data-dropdown-open');
    }
  }

  // Private methods

  _positionDropdown() {
    if (!this.hasMenuTarget || !this.hasButtonTarget) return;

    // Get dimensions and positions
    const buttonRect = this.buttonTarget.getBoundingClientRect();
    const menuWidth = this.menuTarget.offsetWidth;
    const windowWidth = window.innerWidth;

    // Check if the dropdown would go off the right edge of the screen
    if (buttonRect.left + menuWidth > windowWidth) {
      this.menuTarget.classList.add('right-0');
      this.menuTarget.classList.remove('left-0');
    } else {
      this.menuTarget.classList.add('left-0');
      this.menuTarget.classList.remove('right-0');
    }

    // Ensure the dropdown appears below the button
    this.menuTarget.classList.add('top-full');
  }

  _handleClickOutside(event) {
    // Don't do anything if we don't have the necessary targets
    if (!this.hasMenuTarget || !this.hasButtonTarget) return;

    // Don't close if clicking on the button or inside the menu
    if (this.buttonTarget.contains(event.target) || this.menuTarget.contains(event.target)) {
      return;
    }

    // Close the dropdown if it's open
    if (!this.menuTarget.classList.contains('opacity-0')) {
      this.close();
    }
  }

  _handleOtherDropdown(event) {
    // Close this dropdown if another one is being opened
    if (event.detail.id !== this.id) {
      this.close();
    }
  }
}