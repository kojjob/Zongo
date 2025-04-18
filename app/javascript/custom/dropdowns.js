// Simple dropdown handler
document.addEventListener('DOMContentLoaded', function() {
  // Get all dropdown toggles
  const dropdownToggles = document.querySelectorAll('[data-dropdown-toggle]');
  
  // Add click event to each toggle
  dropdownToggles.forEach(toggle => {
    toggle.addEventListener('click', function(e) {
      e.preventDefault();
      e.stopPropagation();
      
      // Get the target dropdown
      const targetId = this.getAttribute('data-dropdown-toggle');
      const target = document.getElementById(targetId);
      
      if (!target) return;
      
      // Toggle the hidden class
      target.classList.toggle('hidden');
      
      // Toggle arrow rotation if present
      const arrow = this.querySelector('svg');
      if (arrow) {
        arrow.classList.toggle('rotate-180');
      }
    });
  });
  
  // Close dropdowns when clicking outside
  document.addEventListener('click', function(e) {
    const dropdowns = document.querySelectorAll('[data-dropdown]');
    
    dropdowns.forEach(dropdown => {
      // Skip if the dropdown is already hidden
      if (dropdown.classList.contains('hidden')) return;
      
      // Skip if clicking inside the dropdown or its toggle
      const toggleId = dropdown.getAttribute('data-dropdown');
      const toggle = document.querySelector(`[data-dropdown-toggle="${toggleId}"]`);
      
      if (dropdown.contains(e.target) || (toggle && toggle.contains(e.target))) return;
      
      // Hide the dropdown
      dropdown.classList.add('hidden');
      
      // Reset arrow rotation
      if (toggle) {
        const arrow = toggle.querySelector('svg');
        if (arrow) {
          arrow.classList.remove('rotate-180');
        }
      }
    });
  });
});
