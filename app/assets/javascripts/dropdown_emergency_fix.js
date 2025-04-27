// Emergency Dropdown Fix
// This script will run after all other scripts and fix any dropdown issues

document.addEventListener('turbo:load', function() {
  console.log('🚨 Applying emergency dropdown fix...');
  
  // Find all dropdown buttons
  const dropdownButtons = document.querySelectorAll('[data-action*="dropdown#toggle"]');
  
  // Remove existing event listeners by cloning and replacing
  dropdownButtons.forEach(function(button) {
    const newButton = button.cloneNode(true);
    if (button.parentNode) {
      button.parentNode.replaceChild(newButton, button);
    }
    
    // Find the associated menu
    const dropdown = newButton.closest('[data-controller*="dropdown"]');
    if (!dropdown) return;
    
    const menu = dropdown.querySelector('[data-dropdown-target="menu"]');
    if (!menu) return;
    
    // Force initial state
    menu.style.display = 'none';
    menu.classList.remove('open');
    
    // Add new click handler
    newButton.addEventListener('click', function(e) {
      e.preventDefault();
      e.stopPropagation();
      
      // Close all other dropdowns
      document.querySelectorAll('[data-dropdown-target="menu"]').forEach(function(otherMenu) {
        if (otherMenu !== menu && otherMenu.style.display !== 'none') {
          otherMenu.style.display = 'none';
          otherMenu.classList.remove('open');
        }
      });
      
      // Toggle this dropdown
      if (menu.style.display === 'none') {
        // Position the dropdown
        if (dropdown.classList.contains('relative')) {
          // User dropdown
          menu.style.position = 'absolute';
          menu.style.top = '100%';
          menu.style.right = '0';
          menu.style.left = 'auto';
          menu.style.marginTop = '0.75rem';
          menu.style.zIndex = '9999';
        } else {
          // Other dropdowns
          menu.style.position = 'absolute';
          menu.style.top = '100%';
          menu.style.left = '0';
          menu.style.marginTop = '0.5rem';
          menu.style.zIndex = '9999';
        }
        
        // Show the dropdown
        menu.style.display = 'block';
        menu.classList.add('open');
        
        // Rotate arrow if it exists
        const arrow = newButton.querySelector('[data-dropdown-target="arrow"]');
        if (arrow) {
          arrow.style.transform = 'rotate(180deg)';
        }
      } else {
        // Hide the dropdown
        menu.style.display = 'none';
        menu.classList.remove('open');
        
        // Reset arrow if it exists
        const arrow = newButton.querySelector('[data-dropdown-target="arrow"]');
        if (arrow) {
          arrow.style.transform = '';
        }
      }
    });
  });
  
  // Close dropdowns when clicking outside
  document.addEventListener('click', function(e) {
    document.querySelectorAll('[data-dropdown-target="menu"]').forEach(function(menu) {
      if (menu.style.display !== 'none') {
        const dropdown = menu.closest('[data-controller*="dropdown"]');
        if (dropdown && !dropdown.contains(e.target)) {
          menu.style.display = 'none';
          menu.classList.remove('open');
          
          // Reset arrow if it exists
          const button = dropdown.querySelector('[data-action*="dropdown#toggle"]');
          if (button) {
            const arrow = button.querySelector('[data-dropdown-target="arrow"]');
            if (arrow) {
              arrow.style.transform = '';
            }
          }
        }
      }
    });
  });
  
  // Close dropdowns when pressing Escape
  document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
      document.querySelectorAll('[data-dropdown-target="menu"]').forEach(function(menu) {
        menu.style.display = 'none';
        menu.classList.remove('open');
        
        // Reset all arrows
        document.querySelectorAll('[data-dropdown-target="arrow"]').forEach(function(arrow) {
          arrow.style.transform = '';
        });
      });
    }
  });
  
  console.log('✅ Emergency dropdown fix applied');
});
