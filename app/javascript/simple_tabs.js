// Simple, reliable tabs implementation
document.addEventListener('DOMContentLoaded', function() {
  console.log('Simple tabs script loaded');
  
  // Find all tab containers with class 'tabs-container'
  const tabContainers = document.querySelectorAll('.tabs-container');
  console.log('Found tab containers:', tabContainers.length);
  
  tabContainers.forEach(container => {
    // Find all tab buttons and panels in this container
    const tabButtons = container.querySelectorAll('.tab-button');
    const tabPanels = container.querySelectorAll('.tab-panel');
    
    console.log('Container found with', tabButtons.length, 'buttons and', tabPanels.length, 'panels');
    
    // Add click event to each tab button
    tabButtons.forEach(button => {
      button.addEventListener('click', function(e) {
        e.preventDefault();
        
        // Get the target panel ID
        const targetId = this.getAttribute('data-target');
        console.log('Tab clicked:', this.textContent.trim(), 'Target:', targetId);
        
        // Deactivate all tabs
        tabButtons.forEach(btn => {
          btn.classList.remove('active-tab', 'border-blue-500', 'dark:border-blue-400', 'text-blue-600', 'dark:text-blue-400');
          btn.classList.add('border-transparent', 'text-gray-500', 'dark:text-gray-400');
        });
        
        // Activate this tab
        this.classList.add('active-tab', 'border-blue-500', 'dark:border-blue-400', 'text-blue-600', 'dark:text-blue-400');
        this.classList.remove('border-transparent', 'text-gray-500', 'dark:text-gray-400');
        
        // Hide all panels
        tabPanels.forEach(panel => {
          panel.classList.add('hidden');
        });
        
        // Show the target panel
        const targetPanel = container.querySelector(`.tab-panel[data-id="${targetId}"]`);
        if (targetPanel) {
          targetPanel.classList.remove('hidden');
          console.log('Showing panel:', targetId);
        } else {
          console.error('Panel not found:', targetId);
        }
      });
    });
    
    // Activate the first tab by default if none is active
    const activeTab = container.querySelector('.tab-button.active-tab');
    if (!activeTab && tabButtons.length > 0) {
      // Simulate a click on the first tab
      tabButtons[0].click();
    }
  });
});
