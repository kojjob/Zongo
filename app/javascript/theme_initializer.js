// Basic theme initializer - runs immediately when loaded
(function() {
  console.log('Theme Initializer running');
  
  // Get the theme from localStorage or use system preference
  const savedTheme = localStorage.getItem('theme');
  const systemPrefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
  
  // Determine if we should use dark mode
  const shouldBeDark = savedTheme === 'dark' || 
                       (savedTheme !== 'light' && systemPrefersDark);
  
  console.log('Theme Initializer:', {
    savedTheme,
    systemPrefersDark,
    shouldBeDark
  });
  
  // Apply the appropriate theme class
  if (shouldBeDark) {
    document.documentElement.classList.add('dark');
    document.documentElement.classList.remove('light');
  } else {
    document.documentElement.classList.remove('dark');
    document.documentElement.classList.add('light');
  }
  
  // Create a global theme manager that can be used throughout the app
  window.ThemeManager = {
    isDark: function() {
      return document.documentElement.classList.contains('dark');
    },
    
    toggle: function() {
      const isDark = this.isDark();
      if (isDark) {
        document.documentElement.classList.remove('dark');
        document.documentElement.classList.add('light');
        localStorage.setItem('theme', 'light');
      } else {
        document.documentElement.classList.add('dark');
        document.documentElement.classList.remove('light');
        localStorage.setItem('theme', 'dark');
      }
      
      // Update any UI elements that need to reflect the theme
      this.updateUI();
      
      return !isDark; // Return the new theme state
    },
    
    updateUI: function() {
      const isDark = this.isDark();
      
      // Update theme indicator if it exists
      const indicator = document.getElementById('theme-indicator');
      if (indicator) {
        indicator.textContent = isDark ? 'dark' : 'light';
      }
      
      // Update any dark/light icons
      const darkIcons = document.querySelectorAll('[data-theme-icon="dark"]');
      const lightIcons = document.querySelectorAll('[data-theme-icon="light"]');
      
      darkIcons.forEach(icon => {
        icon.classList.toggle('hidden', isDark);
      });
      
      lightIcons.forEach(icon => {
        icon.classList.toggle('hidden', !isDark);
      });
      
      // Dispatch event for other components to listen to
      document.dispatchEvent(new CustomEvent('themeChanged', {
        detail: { theme: isDark ? 'dark' : 'light' }
      }));
      
      console.log('Theme toggled to:', isDark ? 'dark' : 'light');
    }
  };
  
  // Initial UI update
  window.ThemeManager.updateUI();
  
  // Set up system preference change listener
  window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', (e) => {
    if (localStorage.getItem('theme') === 'system' || !localStorage.getItem('theme')) {
      if (e.matches) {
        document.documentElement.classList.add('dark');
        document.documentElement.classList.remove('light');
      } else {
        document.documentElement.classList.remove('dark');
        document.documentElement.classList.add('light');
      }
      window.ThemeManager.updateUI();
    }
  });
  
  // Initialize the page as soon as it's loaded
  window.addEventListener('DOMContentLoaded', () => {
    window.ThemeManager.updateUI();
    console.log('Theme Initializer: DOM loaded, UI updated');
  });
  
  console.log('Theme Initializer loaded. ThemeManager attached to window.');
})();
