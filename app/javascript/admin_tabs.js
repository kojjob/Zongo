// Admin-specific tabs implementation
document.addEventListener('DOMContentLoaded', function() {
  console.log('Admin tabs component loaded');
  
  // Initialize admin tabs container
  initializeAdminTabs();
  
  // This function can be called again if new tab containers are added dynamically
  window.initializeAdminTabs = initializeAdminTabs;
  
  function initializeAdminTabs() {
    const tabContainers = document.querySelectorAll('.admin-tabs-container');
    console.log('Found admin tab containers:', tabContainers.length);
    
    tabContainers.forEach(container => {
      // Find all tab buttons and panels in this container
      const tabButtons = container.querySelectorAll('.admin-tab-button');
      const tabPanels = container.querySelectorAll('.admin-tab-panel');
      
      console.log('Admin container found with', tabButtons.length, 'buttons and', tabPanels.length, 'panels');
      
      // Add click event to each tab button
      tabButtons.forEach(button => {
        // Skip if already initialized
        if (button.dataset.initialized === 'true') return;
        
        button.dataset.initialized = 'true';
        button.addEventListener('click', function(e) {
          e.preventDefault();
          
          // Get the target panel ID
          const targetId = this.getAttribute('data-target');
          console.log('Admin tab clicked:', this.textContent.trim(), 'Target:', targetId);
          
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
          const targetPanel = container.querySelector(`.admin-tab-panel[data-id="${targetId}"]`);
          if (targetPanel) {
            targetPanel.classList.remove('hidden');
            console.log('Showing admin panel:', targetId);
          } else {
            console.error('Admin panel not found:', targetId);
          }
        });
      });
      
      // Activate the first tab by default if none is active
      const activeTab = container.querySelector('.admin-tab-button.active-tab');
      if (activeTab) {
        console.log('Found active admin tab:', activeTab.textContent.trim());
      } else if (tabButtons.length > 0) {
        console.log('No active admin tab found, activating first tab');
        // Simulate a click on the first tab
        tabButtons[0].click();
      }
    });
  }
});
