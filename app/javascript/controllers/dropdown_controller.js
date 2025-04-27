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
    const isOpen = this.menuTarget.classList.contains('open');

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

    // Make sure the parent element has the dropdown-container class
    this.element.classList.add('dropdown-container');

    // Show the dropdown
    this.menuTarget.style.display = 'block';
    this.menuTarget.classList.add('open');
    this.menuTarget.classList.remove('opacity-0', 'pointer-events-none', 'scale-95');
    this.menuTarget.classList.add('opacity-100', 'scale-100');

    // Ensure proper z-index
    this.menuTarget.style.zIndex = '50';

    // Update button state
    if (this.hasButtonTarget) {
      this.buttonTarget.setAttribute('data-dropdown-open', '');
      this.buttonTarget.setAttribute('aria-expanded', 'true');

      // Rotate arrow if it exists
      const arrow = this.buttonTarget.querySelector('[data-dropdown-target="arrow"]');
      if (arrow) {
        arrow.classList.add('open');
      }
    }
  }

  close() {
    if (!this.hasMenuTarget) return;

    // Hide the dropdown
    this.menuTarget.style.display = 'none';
    this.menuTarget.classList.remove('open');
    this.menuTarget.classList.remove('opacity-100', 'scale-100');
    this.menuTarget.classList.add('opacity-0', 'pointer-events-none', 'scale-95');

    // Update button state
    if (this.hasButtonTarget) {
      this.buttonTarget.removeAttribute('data-dropdown-open');
      this.buttonTarget.setAttribute('aria-expanded', 'false');

      // Rotate arrow back if it exists
      const arrow = this.buttonTarget.querySelector('[data-dropdown-target="arrow"]');
      if (arrow) {
        arrow.classList.remove('open');
      }
    }
  }

  // Private methods

  _positionDropdown() {
    if (!this.hasMenuTarget || !this.hasButtonTarget) return;

    // Get dimensions and positions
    const buttonRect = this.buttonTarget.getBoundingClientRect();
    const menuWidth = this.menuTarget.offsetWidth;
    const windowWidth = window.innerWidth;
    const isMobile = windowWidth < 640;

    // Reset positioning classes
    this.menuTarget.classList.remove('right-0', 'left-0', 'top-full', 'bottom-0', 'fixed', 'absolute');

    if (isMobile) {
      // Mobile positioning (bottom sheet)
      this.menuTarget.classList.add('fixed', 'bottom-0', 'left-0', 'right-0', 'w-full');
      this.menuTarget.style.maxHeight = '80vh';
      this.menuTarget.style.overflowY = 'auto';
      this.menuTarget.style.borderRadius = '1rem 1rem 0 0';
      this.menuTarget.style.transform = 'translateY(0)';
    } else {
      // Desktop positioning
      this.menuTarget.classList.add('absolute');

      // Check if the dropdown would go off the right edge of the screen
      if (buttonRect.left + menuWidth > windowWidth) {
        this.menuTarget.classList.add('right-0');
      } else {
        this.menuTarget.classList.add('left-0');
      }

      // Ensure the dropdown appears below the button
      this.menuTarget.classList.add('top-full');
      this.menuTarget.style.marginTop = '0.75rem';
      this.menuTarget.style.maxHeight = '';
      this.menuTarget.style.overflowY = '';
      this.menuTarget.style.borderRadius = '';
      this.menuTarget.style.transform = '';
    }
  }

  _handleClickOutside(event) {
    // Don't do anything if we don't have the necessary targets
    if (!this.hasMenuTarget || !this.hasButtonTarget) return;

    // Don't close if clicking on the button or inside the menu
    if (this.buttonTarget.contains(event.target) || this.menuTarget.contains(event.target)) {
      return;
    }

    // Close the dropdown if it's open
    if (this.menuTarget.classList.contains('open')) {
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