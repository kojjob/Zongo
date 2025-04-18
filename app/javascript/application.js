// Load theme initializer first to ensure theme is set ASAP
import "theme_initializer"

// Configure your import map in config/importmap.rb
// Entry point for the build script in your package.json

import "@hotwired/turbo-rails"
import "./controllers"
import "./tabs"
import "./lightbox"
import "./test_tabs" // Temporary for debugging
import "./simple_tabs" // New simplified tabs implementation
import "./components/tabs" // Reusable tabs component
import "./admin_tabs" // Admin-specific tabs implementation
import "./custom/dropdowns" // Custom dropdowns implementation
import "./custom/advanced_animations" // Advanced animations and micro-interactions
import "./custom/simple_accordion" // Simple accordion for FAQ section
import "./debug_tabs" // Debug script for tab navigation

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

  // Debug Stimulus controllers
  console.log('Application initialized');

  // Check if tabs controller is registered
  if (window.Stimulus) {
    console.log('Stimulus is available');
    console.log('Registered controllers:', Object.keys(window.Stimulus.application.controllers).join(', '));
  } else {
    console.log('Stimulus is not available');
  }

  // Check for tabs elements
  const tabsContainer = document.querySelector('[data-controller="tabs"]');
  if (tabsContainer) {
    console.log('Tabs container found:', tabsContainer);
    console.log('Tab buttons:', tabsContainer.querySelectorAll('[data-tabs-target="tab"]').length);
    console.log('Tab panels:', tabsContainer.querySelectorAll('[data-tabs-target="panel"]').length);
  } else {
    console.log('No tabs container found');
  }
});
