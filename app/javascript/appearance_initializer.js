// Appearance settings initializer - runs immediately when loaded
(function() {
  console.log('Appearance Initializer running');
  
  // Apply text size from localStorage or default to medium (3)
  function applyTextSize() {
    const savedTextSize = localStorage.getItem('textSize') || '3';
    
    // Remove any existing text size classes
    document.documentElement.classList.remove('text-size-1', 'text-size-2', 'text-size-3', 'text-size-4', 'text-size-5');
    
    // Add the new text size class
    document.documentElement.classList.add(`text-size-${savedTextSize}`);
    
    console.log(`Applied text size: ${savedTextSize}`);
  }
  
  // Apply high contrast mode if enabled
  function applyHighContrast() {
    const highContrastEnabled = localStorage.getItem('highContrast') === 'true';
    
    if (highContrastEnabled) {
      document.documentElement.classList.add('high-contrast');
    } else {
      document.documentElement.classList.remove('high-contrast');
    }
    
    console.log(`Applied high contrast mode: ${highContrastEnabled}`);
  }
  
  // Apply reduce motion if enabled
  function applyReduceMotion() {
    const reduceMotionEnabled = localStorage.getItem('reduceMotion') === 'true';
    
    if (reduceMotionEnabled) {
      document.documentElement.classList.add('reduce-motion');
    } else {
      document.documentElement.classList.remove('reduce-motion');
    }
    
    console.log(`Applied reduce motion: ${reduceMotionEnabled}`);
  }
  
  // Apply all appearance settings
  function applyAllSettings() {
    applyTextSize();
    applyHighContrast();
    applyReduceMotion();
  }
  
  // Apply settings on page load
  document.addEventListener('DOMContentLoaded', applyAllSettings);
  
  // Apply settings immediately in case this script runs after DOMContentLoaded
  applyAllSettings();
  
  // Listen for custom events to update settings
  document.addEventListener('textSizeChanged', (event) => {
    const size = event.detail.size;
    localStorage.setItem('textSize', size);
    applyTextSize();
  });
  
  document.addEventListener('highContrastChanged', (event) => {
    const enabled = event.detail.enabled;
    localStorage.setItem('highContrast', enabled);
    applyHighContrast();
  });
  
  document.addEventListener('reduceMotionChanged', (event) => {
    const enabled = event.detail.enabled;
    localStorage.setItem('reduceMotion', enabled);
    applyReduceMotion();
  });
  
  console.log('Appearance Initializer loaded');
})();
