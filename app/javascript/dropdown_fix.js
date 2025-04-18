/**
 * Dropdown Fix - Standalone Solution
 * 
 * This script fixes the issue where all dropdowns toggle at once by properly
 * isolating each dropdown instance and ensuring they work correctly on both
 * desktop and mobile devices.
 */

document.addEventListener('DOMContentLoaded', function() {
  console.log('🔄 Applying dropdown fix...');
  
  // Find all dropdown controllers
  const dropdownElements = document.querySelectorAll('[data-controller*="dropdown"]');

  // Create a map to store dropdown relationships
  const dropdownMap = new Map();

  // First pass: assign unique IDs and build the relationship map
  dropdownElements.forEach((dropdown, index) => {
    // Find toggle button and menu
    const toggle = dropdown.querySelector('[data-action*="dropdown#toggle"]');
    const menu = dropdown.querySelector('[data-dropdown-target="menu"]');

    if (toggle && menu) {
      // Assign a unique ID to each dropdown
      const dropdownId = `dropdown-${index}-${Math.random().toString(36).substring(2, 8)}`;
      dropdown.dataset.dropdownId = dropdownId;
      toggle.dataset.dropdownId = dropdownId;
      menu.dataset.dropdownId = dropdownId;
      
      // Store the relationship in our map
      dropdownMap.set(dropdownId, { dropdown, toggle, menu });
    }
  });

  // Second pass: set up event listeners with proper isolation
  dropdownMap.forEach(({ dropdown, toggle, menu }, dropdownId) => {
    // Remove the original event listener by cloning
    const toggleClone = toggle.cloneNode(true);
    toggle.parentNode.replaceChild(toggleClone, toggle);
    
    // Preserve the data attribute
    toggleClone.dataset.dropdownId = dropdownId;

    // Add our direct toggle function with improved responsive behavior
    toggleClone.addEventListener('click', function(e) {
      e.preventDefault();
      e.stopPropagation();

      // Close all other dropdowns but not this one
      dropdownMap.forEach((item, id) => {
        if (id !== dropdownId && !item.menu.classList.contains('hidden')) {
          hideDropdownMenu(item.menu);
        }
      });

      // Toggle ONLY this specific menu with animation
      if (menu.classList.contains('hidden')) {
        showDropdownMenu(menu);
      } else {
        hideDropdownMenu(menu);
      }
    });

    // Add touch events for better mobile support
    toggleClone.addEventListener('touchend', function(e) {
      e.preventDefault();
      e.stopPropagation();

      // Close all other dropdowns but not this one
      dropdownMap.forEach((item, id) => {
        if (id !== dropdownId && !item.menu.classList.contains('hidden')) {
          hideDropdownMenu(item.menu);
        }
      });

      // Toggle this menu with animation
      if (menu.classList.contains('hidden')) {
        showDropdownMenu(menu);
      } else {
        hideDropdownMenu(menu);
      }
    });

    // Make all links in the dropdown responsive to touch
    menu.querySelectorAll('a, button').forEach(element => {
      // Clone to remove existing listeners
      const elementClone = element.cloneNode(true);
      element.parentNode.replaceChild(elementClone, element);

      // Add touch event listener
      elementClone.addEventListener('touchend', function(e) {
        e.stopPropagation();
        // Don't prevent default to allow navigation

        // For mobile: add a slight delay to ensure the tap is registered
        if (window.innerWidth <= 640) {
          const href = elementClone.getAttribute('href');
          const isButton = elementClone.tagName.toLowerCase() === 'button';

          if (href || isButton) {
            // Add active state visual feedback
            elementClone.classList.add('active-tap');

            // Remove active state after a short delay
            setTimeout(() => {
              elementClone.classList.remove('active-tap');

              // If it's a link with href, navigate to it
              if (href) {
                window.location.href = href;
              }

              // If it's a button, trigger a click
              if (isButton) {
                elementClone.click();
              }

              // Hide the dropdown after navigation
              hideDropdownMenu(menu);
            }, 150);
          }
        }
      });
    });

    console.log('Fixed dropdown with responsive behavior:', toggle);
  });

  // Helper function to show dropdown menu with animation
  function showDropdownMenu(menu) {
    menu.classList.remove('hidden');
    // Use setTimeout to ensure the transition happens after the display change
    setTimeout(() => {
      menu.classList.remove('opacity-0', 'scale-95', 'pointer-events-none');
      menu.classList.add('opacity-100', 'scale-100', 'pointer-events-auto');
    }, 10);
  }

  // Helper function to hide dropdown menu with animation
  function hideDropdownMenu(menu) {
    menu.classList.add('opacity-0', 'scale-95', 'pointer-events-none');
    menu.classList.remove('opacity-100', 'scale-100', 'pointer-events-auto');

    // Wait for animation to complete before hiding
    setTimeout(() => {
      menu.classList.add('hidden');
    }, 150);
  }

  // Close dropdowns when clicking outside
  document.addEventListener('click', function(e) {
    document.querySelectorAll('[data-dropdown-target="menu"]').forEach(menu => {
      if (!menu.classList.contains('hidden')) {
        const dropdown = menu.closest('[data-controller*="dropdown"]');

        if (dropdown && !dropdown.contains(e.target)) {
          hideDropdownMenu(menu);
        }
      }
    });
  });

  // Add touch event for mobile devices
  document.addEventListener('touchend', function(e) {
    document.querySelectorAll('[data-dropdown-target="menu"]').forEach(menu => {
      if (!menu.classList.contains('hidden')) {
        const dropdown = menu.closest('[data-controller*="dropdown"]');

        if (dropdown && !dropdown.contains(e.target)) {
          hideDropdownMenu(menu);
        }
      }
    });
  });

  // Close dropdowns when pressing Escape
  document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
      document.querySelectorAll('[data-dropdown-target="menu"]').forEach(menu => {
        hideDropdownMenu(menu);
      });
    }
  });

  console.log('✅ Dropdown fix applied successfully');
});