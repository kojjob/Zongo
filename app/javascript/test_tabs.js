// Test script to ensure tabs are working
document.addEventListener('DOMContentLoaded', function() {
  console.log('Test tabs script loaded');
  
  // Wait a bit to ensure everything is loaded
  setTimeout(function() {
    // Find all tab containers
    const tabContainers = document.querySelectorAll('[data-controller="tabs"]');
    console.log('Found tab containers:', tabContainers.length);
    
    if (tabContainers.length > 0) {
      const container = tabContainers[0];
      const tabs = container.querySelectorAll('[data-tabs-target="tab"]');
      const panels = container.querySelectorAll('[data-tabs-target="panel"]');
      
      console.log('Found tabs:', tabs.length);
      console.log('Found panels:', panels.length);
      
      // Test clicking each tab
      tabs.forEach((tab, index) => {
        if (index > 0) { // Skip the first tab which is already active
          console.log(`Testing click on tab ${index}:`, tab.textContent.trim());
          
          // Simulate a click on the tab
          const event = new MouseEvent('click', {
            bubbles: true,
            cancelable: true,
            view: window
          });
          
          tab.dispatchEvent(event);
          
          // Log the state after clicking
          console.log('Active tab after click:', 
            Array.from(tabs).find(t => t.classList.contains('active-tab'))?.textContent.trim());
          console.log('Visible panel:', 
            Array.from(panels).find(p => !p.classList.contains('hidden'))?.getAttribute('data-tab-id'));
        }
      });
    }
  }, 1000);
});
