// This script runs before Stimulus loads to prevent flash of incorrect theme

// Make theme helpers globally available
window.ThemeManager = {
  // Check for saved theme preference or use system preference
  getTheme: function() {
    const savedTheme = localStorage.getItem('theme')
    
    if (savedTheme) {
      return savedTheme
    }
    
    // Check system preference
    return window.matchMedia('(prefers-color-scheme: dark)').matches 
      ? 'dark' 
      : 'light'
  },
  
  // Check if dark mode is active
  isDarkMode: function() {
    return this.getTheme() === 'dark'
  },
  
  // Set theme and update DOM
  setTheme: function(theme) {
    if (theme === 'dark') {
      document.documentElement.classList.add('dark')
    } else {
      document.documentElement.classList.remove('dark')
    }
    
    localStorage.setItem('theme', theme)
    document.dispatchEvent(new CustomEvent('theme-changed', { 
      detail: { theme: theme },
      bubbles: true
    }))
    
    return theme
  }
}

// Immediately invoked function to set initial theme
;(function() {
  // Apply theme immediately to prevent flash
  const theme = window.ThemeManager.getTheme()
  
  // Force application of theme class - important for landing page
  if (theme === 'dark') {
    document.documentElement.classList.add('dark')
  } else {
    document.documentElement.classList.remove('dark')
  }
  
  // Handle landing page specifically 
  const isLandingPage = window.location.pathname === '/' || window.location.pathname === '/home';
  if (isLandingPage) {
    console.log('Landing page detected - ensuring proper theme application');
    setTimeout(function() {
      // Re-apply theme after a slight delay to ensure it takes
      if (theme === 'dark') {
        document.documentElement.classList.add('dark')
      } else {
        document.documentElement.classList.remove('dark')
      }
    }, 50);
  }
  
  // Make current theme available globally
  window.currentTheme = theme
  
  // Update theme indicator if it exists
  const themeIndicator = document.getElementById('theme-indicator')
  if (themeIndicator) {
    themeIndicator.textContent = theme
  }
  
  // Log theme initialization
  console.log('Theme initialized:', theme)
  
  // Add event listener to document for theme changes
  document.addEventListener('theme-changed', function(e) {
    console.log('Theme changed event received:', e.detail.theme)
  })
})();