// Load theme initializer first to ensure theme is set ASAP
import "theme_initializer"

// Configure your import map in config/importmap.rb
// Entry point for the build script in your package.json

import "@hotwired/turbo-rails"
import "./controllers"

// Early theme initialization to prevent flash of wrong theme
// (This will be handled more thoroughly by the theme controller)
(function() {
  const savedTheme = localStorage.getItem('theme');
  const systemPrefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
  const isDark = savedTheme === 'dark' || (savedTheme === 'system' && systemPrefersDark) || (!savedTheme && systemPrefersDark);
  
  if (isDark) {
    document.documentElement.classList.add('dark');
    document.documentElement.classList.remove('light');
  } else {
    document.documentElement.classList.remove('dark');
    document.documentElement.classList.add('light');
  }
})();

// Remove initializing class when DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
  setTimeout(function() {
    document.documentElement.classList.remove('theme-initializing');
  }, 50);
});
