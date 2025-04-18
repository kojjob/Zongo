// Simple tabs functionality
document.addEventListener('DOMContentLoaded', function() {
  // Find all tab containers
  const tabContainers = document.querySelectorAll('[data-controller="tabs"]');
  
  tabContainers.forEach(container => {
    const tabs = container.querySelectorAll('[data-tabs-target="tab"]');
    const panels = container.querySelectorAll('[data-tabs-target="panel"]');
    
    // Add click event listeners to tabs
    tabs.forEach(tab => {
      tab.addEventListener('click', function(e) {
        e.preventDefault();
        const tabId = this.getAttribute('data-tab-id');
        
        // Deactivate all tabs
        tabs.forEach(t => {
          t.classList.remove('active-tab', 'border-blue-500', 'dark:border-blue-400', 'text-blue-600', 'dark:text-blue-400');
          t.classList.add('border-transparent', 'text-gray-500', 'dark:text-gray-400');
        });
        
        // Activate clicked tab
        this.classList.add('active-tab', 'border-blue-500', 'dark:border-blue-400', 'text-blue-600', 'dark:text-blue-400');
        this.classList.remove('border-transparent', 'text-gray-500', 'dark:text-gray-400');
        
        // Hide all panels
        panels.forEach(panel => {
          panel.classList.add('hidden');
        });
        
        // Show corresponding panel
        const panel = Array.from(panels).find(p => p.getAttribute('data-tab-id') === tabId);
        if (panel) {
          panel.classList.remove('hidden');
        }
      });
    });
  });
});
