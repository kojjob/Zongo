import { Controller } from "@hotwired/stimulus"

// Controller for handling theme mode selection in the appearance settings
export default class extends Controller {
  static targets = ["lightOption", "darkOption", "autoOption", "lightCard", "darkCard", "autoCard", "lightCheck", "darkCheck", "autoCheck"]

  connect() {
    console.log("ThemeModeController connected");

    // Get the user's saved preference from the radio buttons
    let userPreference = null;

    if (this.hasLightOptionTarget && this.lightOptionTarget.checked) {
      userPreference = "light";
    } else if (this.hasDarkOptionTarget && this.darkOptionTarget.checked) {
      userPreference = "dark";
    } else if (this.hasAutoOptionTarget && this.autoOptionTarget.checked) {
      userPreference = "auto";
    }

    console.log("User's saved theme preference:", userPreference);

    // Apply the user's preference immediately
    if (userPreference) {
      // Store in localStorage to match the theme_initializer.js behavior
      if (userPreference === "light" || userPreference === "dark") {
        localStorage.setItem("theme", userPreference);
      } else if (userPreference === "auto") {
        localStorage.removeItem("theme");
      }

      // Apply the theme immediately
      this.applyTheme(userPreference);
    }

    // Update the UI to reflect the current selection
    this.updateSelectedOption();
  }

  // Apply the theme based on the selected mode
  applyTheme(mode) {
    if (mode === "light") {
      document.documentElement.classList.remove("dark");
    } else if (mode === "dark") {
      document.documentElement.classList.add("dark");
    } else if (mode === "auto") {
      // For auto/system mode, use the system preference
      if (window.matchMedia("(prefers-color-scheme: dark)").matches) {
        document.documentElement.classList.add("dark");
      } else {
        document.documentElement.classList.remove("dark");
      }
    }

    console.log(`Applied theme: ${mode}`);
  }

  // Set the theme mode when a radio button is clicked
  setMode(event) {
    const mode = event.currentTarget.value;
    console.log(`Setting theme mode to: ${mode}`);

    // Update the data attribute on the container
    const container = this.element.closest('[data-theme-preference]');
    if (container) {
      container.dataset.themePreference = mode;
    }

    // Store the preference in localStorage
    if (mode === "light" || mode === "dark") {
      localStorage.setItem("theme", mode);
    } else if (mode === "auto") {
      // For auto/system mode, remove from localStorage to use system preference
      localStorage.removeItem("theme");
    }

    // Apply the theme immediately
    this.applyTheme(mode);

    // Update the UI to reflect the selection
    this.updateSelectedOption();

    // Save the preference to the server
    this.saveThemePreference(mode);
  }

  // Save the theme preference to the server
  saveThemePreference(mode) {
    // Get the form element
    const form = this.element.closest('form');
    if (!form) {
      console.error('Could not find form element');
      return;
    }

    // Create form data from the form
    const formData = new FormData(form);

    // Send AJAX request
    fetch(form.action, {
      method: form.method || 'POST',
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest'
      },
      body: formData
    })
    .then(response => {
      if (!response.ok) {
        throw new Error('Network response was not ok');
      }
      return response.json();
    })
    .then(data => {
      console.log('Theme preference saved:', data);

      // Show a success message
      this.showNotification('Theme preference saved successfully', 'success');
    })
    .catch(error => {
      console.error('Error saving theme preference:', error);

      // Show an error message
      this.showNotification('Failed to save theme preference', 'error');
    });
  }

  // Show a notification message
  showNotification(message, type = 'info') {
    // Create notification element
    const notification = document.createElement('div');
    notification.className = `fixed bottom-4 right-4 px-6 py-3 rounded-lg shadow-lg z-50 ${
      type === 'success' ? 'bg-green-500 text-white' :
      type === 'error' ? 'bg-red-500 text-white' :
      'bg-blue-500 text-white'
    }`;
    notification.style.transition = 'all 0.3s ease-in-out';
    notification.style.opacity = '0';
    notification.style.transform = 'translateY(20px)';

    // Add icon based on type
    const icon = document.createElement('i');
    icon.className = `fas fa-${
      type === 'success' ? 'check-circle' :
      type === 'error' ? 'exclamation-circle' :
      'info-circle'
    } mr-2`;
    notification.appendChild(icon);

    // Add message text
    const text = document.createTextNode(message);
    notification.appendChild(text);

    // Add to DOM
    document.body.appendChild(notification);

    // Trigger animation
    setTimeout(() => {
      notification.style.opacity = '1';
      notification.style.transform = 'translateY(0)';
    }, 10);

    // Remove after delay
    setTimeout(() => {
      notification.style.opacity = '0';
      notification.style.transform = 'translateY(20px)';

      setTimeout(() => {
        document.body.removeChild(notification);
      }, 300);
    }, 3000);
  }

  // Update the UI to reflect the current theme mode
  updateSelectedOption() {
    // First check if we have a user preference in the data attribute
    const container = this.element.closest('[data-theme-preference]');
    const userPreference = container ? container.dataset.themePreference : null;

    // Get the current theme mode from localStorage
    const storedTheme = localStorage.getItem("theme");
    const systemPrefersDark = window.matchMedia("(prefers-color-scheme: dark)").matches;

    // Determine the current mode
    let currentMode;

    // If we have a user preference, use that first
    if (userPreference && (userPreference === 'light' || userPreference === 'dark' || userPreference === 'auto')) {
      currentMode = userPreference;
    }
    // Otherwise use localStorage
    else if (storedTheme === "light") {
      currentMode = "light";
    } else if (storedTheme === "dark") {
      currentMode = "dark";
    } else {
      currentMode = "auto";
    }

    console.log(`Current theme mode: ${currentMode}`);

    // Update the radio buttons
    if (this.hasLightOptionTarget) {
      this.lightOptionTarget.checked = (currentMode === "light");
    }

    if (this.hasDarkOptionTarget) {
      this.darkOptionTarget.checked = (currentMode === "dark");
    }

    if (this.hasAutoOptionTarget) {
      this.autoOptionTarget.checked = (currentMode === "auto");
    }

    // Update the border colors on the cards
    this.updateCardBorders(currentMode);
  }

  // Update the border colors on the theme cards
  updateCardBorders(currentMode) {
    if (!this.hasLightCardTarget || !this.hasDarkCardTarget || !this.hasAutoCardTarget) {
      console.warn("Missing card targets");
      return;
    }

    // Remove all highlight borders
    this.lightCardTarget.classList.remove('border-indigo-500');
    this.darkCardTarget.classList.remove('border-indigo-500');
    this.autoCardTarget.classList.remove('border-indigo-500');

    // Add the default border color
    this.lightCardTarget.classList.add('border-gray-200', 'dark:border-gray-700');
    this.darkCardTarget.classList.add('border-gray-200', 'dark:border-gray-700');
    this.autoCardTarget.classList.add('border-gray-200', 'dark:border-gray-700');

    // Add the highlight border to the selected card
    if (currentMode === 'light') {
      this.lightCardTarget.classList.remove('border-gray-200', 'dark:border-gray-700');
      this.lightCardTarget.classList.add('border-indigo-500');
    } else if (currentMode === 'dark') {
      this.darkCardTarget.classList.remove('border-gray-200', 'dark:border-gray-700');
      this.darkCardTarget.classList.add('border-indigo-500');
    } else {
      this.autoCardTarget.classList.remove('border-gray-200', 'dark:border-gray-700');
      this.autoCardTarget.classList.add('border-indigo-500');
    }

    // Update the check marks
    this.updateCheckMarks(currentMode);
  }

  // Update the check marks on the theme cards
  updateCheckMarks(currentMode) {
    if (!this.hasLightCheckTarget || !this.hasDarkCheckTarget || !this.hasAutoCheckTarget) {
      console.warn("Missing check mark targets");
      return;
    }

    // Hide all check marks
    this.lightCheckTarget.classList.add('hidden');
    this.darkCheckTarget.classList.add('hidden');
    this.autoCheckTarget.classList.add('hidden');

    // Show the check mark for the selected card
    if (currentMode === 'light') {
      this.lightCheckTarget.classList.remove('hidden');
    } else if (currentMode === 'dark') {
      this.darkCheckTarget.classList.remove('hidden');
    } else {
      this.autoCheckTarget.classList.remove('hidden');
    }
  }
}
