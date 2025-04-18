// Debug script to help identify tab navigation issues
document.addEventListener('DOMContentLoaded', function() {
  console.log('Debug script loaded');
  
  // Check if the tab navigation controller is present
  const tabNavController = document.querySelector('[data-controller="tab-navigation"]');
  if (tabNavController) {
    console.log('Tab navigation controller found:', tabNavController);
    
    // Check tab buttons
    const tabButtons = tabNavController.querySelectorAll('[data-tab-navigation-target="tab"]');
    console.log('Tab buttons found:', tabButtons.length);
    tabButtons.forEach((button, index) => {
      console.log(`Tab ${index + 1}:`, button.dataset.target);
    });
    
    // Check tab panels
    const tabPanels = tabNavController.querySelectorAll('[data-tab-navigation-target="panel"]');
    console.log('Tab panels found:', tabPanels.length);
    tabPanels.forEach((panel, index) => {
      console.log(`Panel ${index + 1}:`, panel.dataset.id);
    });
    
    // Check active tab
    const activeTab = tabNavController.querySelector('.active-tab');
    if (activeTab) {
      console.log('Active tab found:', activeTab.dataset.target);
    } else {
      console.log('No active tab found');
    }
  } else {
    console.log('Tab navigation controller not found');
  }
});
