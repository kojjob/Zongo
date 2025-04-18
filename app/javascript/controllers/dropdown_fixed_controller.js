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
    this._escapeHandler = this._handleEscape.bind(this);
    
    // Add event listeners
    document.addEventListener('click', this._clickOutsideHandler);
    document.addEventListener('keydown', this._escapeHandler);
  }

  disconnect() {
    // Clean up event listeners
    document.removeEventListener('click', this._clickOutsideHandler);
    document.removeEventListener('keydown', this._escapeHandler);
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
      // If closed, open it and close other dropdowns
      this.closeAllDropdowns();
      this.open();
    }
  }

  open() {
    if (!this.hasMenuTarget) return;

    // Remove hidden class if it exists
    this.menuTarget.classList.remove('hidden');
    
    // Position the dropdown correctly
    this._positionDropdown();

    // Show the dropdown with animation
    setTimeout(() => {
      this.menuTarget.classList.remove('opacity-0', 'scale-95', 'pointer-events-none');
      this.menuTarget.classList.add('opacity-100', 'scale-100', 'pointer-events-auto');
    }, 10);

    // Update button state
    if (this.hasButtonTarget) {
      this.buttonTarget.setAttribute('aria-expanded', 'true');
    }
  }

  close() {
    if (!this.hasMenuTarget) return;

    // Hide the dropdown with animation
    this.menuTarget.classList.remove('opacity-100', 'scale-100', 'pointer-events-auto');
    this.menuTarget.classList.add('opacity-0', 'scale-95', 'pointer-events-none');

    // Add hidden class after animation completes
    setTimeout(() => {
      this.menuTarget.classList.add('hidden');
    }, 150);

    // Update button state
    if (this.hasButtonTarget) {
      this.buttonTarget.setAttribute('aria-expanded', 'false');
    }
  }

  closeAllDropdowns() {
    // Find all dropdown controllers
    const dropdownControllers = document.querySelectorAll('[data-controller*="dropdown"]');
    
    // Close each dropdown except this one
    dropdownControllers.forEach(dropdown => {
      // Skip if it's this controller
      if (dropdown === this.element) return;
      
      // Find the menu
      const menu = dropdown.querySelector('[data-dropdown-target="menu"]');
      if (!menu) return;
      
      // Add animation classes
      menu.classList.remove('opacity-100', 'scale-100', 'pointer-events-auto');
      menu.classList.add('opacity-0', 'scale-95', 'pointer-events-none');
      
      // Add hidden class after animation
      setTimeout(() => {
        menu.classList.add('hidden');
      }, 150);
      
      // Update button state
      const button = dropdown.querySelector('[data-dropdown-target="button"]');
      if (button) {
        button.setAttribute('aria-expanded', 'false');
      }
    });
  }

  // Private methods

  _positionDropdown() {
    if (!this.hasMenuTarget || !this.hasButtonTarget) return;

    // Get dimensions and positions
    const buttonRect = this.buttonTarget.getBoundingClientRect();
    const menuWidth = this.menuTarget.offsetWidth;
    const windowWidth = window.innerWidth;
    
    // Check if we're on mobile
    const isMobile = window.innerWidth <= 640;
    
    if (isMobile) {
      // Mobile-specific positioning
      this.menuTarget.classList.add('fixed', 'left-0', 'right-0', 'w-full');
      this.menuTarget.classList.remove('absolute');
      
      // Check if this is a user dropdown
      const isUserDropdown = this.element.classList.contains('user-dropdown');
      if (isUserDropdown) {
        this.menuTarget.classList.add('bottom-0');
        this.menuTarget.classList.remove('top-full');
      } else {
        this.menuTarget.classList.add('top-full');
        this.menuTarget.classList.remove('bottom-0');
      }
    } else {
      // Desktop positioning
      this.menuTarget.classList.add('absolute');
      this.menuTarget.classList.remove('fixed', 'left-0', 'right-0', 'w-full');
      
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
  }

  _handleClickOutside(event) {
    // Don't do anything if we don't have the necessary targets
    if (!this.hasMenuTarget) return;

    // Don't close if clicking on the button or inside the menu
    if (this.element.contains(event.target)) {
      return;
    }

    // Close the dropdown if it's open
    if (!this.menuTarget.classList.contains('opacity-0')) {
      this.close();
    }
  }

  _handleEscape(event) {
    // Close on Escape key
    if (event.key === 'Escape' && !this.menuTarget.classList.contains('opacity-0')) {
      this.close();
    }
  }
}