import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "mobileMenu", 
    "profileMenu", 
    "notificationPanel", 
    "searchPanel",
    "walletDropdown",
    "walletInfo",
    "searchInput",
    "notificationCount",
    "backdrop",
    "searchBar"
  ]
  
  static values = {
    notificationCount: Number,
    scrolled: Boolean
  }
  
  connect() {
    console.log("Navbar controller connected");
    
    // Set initial scrolled state
    this.scrolledValue = window.scrollY > 10
    
    // Add event listeners
    this.boundHandleScroll = this.handleScroll.bind(this)
    this.boundClickOutside = this.clickOutside.bind(this)
    
    window.addEventListener('scroll', this.boundHandleScroll)
    document.addEventListener('click', this.boundClickOutside)
    
    // Initialize theme icons if theme controller exists
    if (this.hasThemeController) {
      this.themeController.updateIcons()
    }
    
    // Log targets for debugging
    this.logTargets();
  }
  
  disconnect() {
    window.removeEventListener('scroll', this.boundHandleScroll)
    document.removeEventListener('click', this.boundClickOutside)
  }
  
  logTargets() {
    console.log("Profile Menu Target:", this.hasProfileMenuTarget);
    console.log("Notification Panel Target:", this.hasNotificationPanelTarget);
    console.log("Search Panel Target:", this.hasSearchPanelTarget);
    console.log("Wallet Dropdown Target:", this.hasWalletDropdownTarget);
    console.log("Mobile Menu Target:", this.hasMobileMenuTarget);
  }
  
  get themeController() {
    return this.application.getControllerForElementAndIdentifier(this.element, 'theme')
  }
  
  get hasThemeController() {
    return this.application.getControllerForElementAndIdentifier(this.element, 'theme') !== undefined
  }
  
  // Mobile menu toggle
  toggleMobileMenu() {
    console.log("Toggle mobile menu called");
    
    if (!this.hasMobileMenuTarget) {
      console.error("Mobile menu target not found");
      return;
    }
    
    // Get the current state
    const isHidden = this.mobileMenuTarget.classList.contains('translate-x-full');
    
    if (isHidden) {
      // Show the menu
      this.mobileMenuTarget.classList.remove('translate-x-full');
      // Prevent scrolling on the body
      document.body.style.overflow = 'hidden';
    } else {
      // Hide the menu
      this.mobileMenuTarget.classList.add('translate-x-full');
      // Allow scrolling again
      document.body.style.overflow = '';
    }
  }
  
  // Toggle search bar for mobile
  toggleSearchBar() {
    console.log("Toggle search bar called");
    
    if (!this.hasSearchBarTarget) {
      console.error("Search bar target not found");
      return;
    }
    
    // Toggle search bar visibility
    this.searchBarTarget.classList.toggle('hidden');
    
    // Focus search input when visible
    if (!this.searchBarTarget.classList.contains('hidden') && this.hasSearchInputTarget) {
      setTimeout(() => {
        this.searchInputTarget.focus();
      }, 100);
    }
  }
  
  // Profile dropdown toggle
  toggleProfileDropdown(event) {
    console.log("Toggle profile dropdown");
    event.stopPropagation()
    
    // Close other dropdowns first
    this.closeAllDropdowns()
    
    // Toggle this dropdown
    this.profileMenuTarget.classList.toggle('hidden')
  }
  
  // Notification panel toggle
  toggleNotificationPanel(event) {
    console.log("Toggle notification panel");
    event.stopPropagation()
    
    // Close other dropdowns first
    this.closeAllDropdowns()
    
    // Toggle this dropdown
    this.notificationPanelTarget.classList.toggle('hidden')
    
    // Reset notification count when opening
    if (!this.notificationPanelTarget.classList.contains('hidden')) {
      this.resetNotificationCount()
    }
  }
  
  // Search panel toggle
  toggleSearchPanel(event) {
    console.log("Toggle search panel");
    event.stopPropagation()
    
    // Close other dropdowns first
    this.closeAllDropdowns()
    
    // Toggle this dropdown
    this.searchPanelTarget.classList.toggle('hidden')
    
    // Focus search input when panel is opened
    if (!this.searchPanelTarget.classList.contains('hidden')) {
      setTimeout(() => {
        if (this.hasSearchInputTarget) {
          this.searchInputTarget.focus()
        }
      }, 100)
    }
  }
  
  // Wallet dropdown toggle
  toggleWalletDropdown(event) {
    console.log("Toggle wallet dropdown");
    event.stopPropagation()
    
    // Close other dropdowns first
    this.closeAllDropdowns()
    
    // Toggle this dropdown
    this.walletDropdownTarget.classList.toggle('hidden')
  }
  
  // Close all dropdowns and panels
  closeAllDropdowns() {
    console.log("Closing all dropdowns");
    
    if (this.hasProfileMenuTarget) {
      this.profileMenuTarget.classList.add('hidden')
    }
    
    if (this.hasNotificationPanelTarget) {
      this.notificationPanelTarget.classList.add('hidden')
    }
    
    if (this.hasSearchPanelTarget) {
      this.searchPanelTarget.classList.add('hidden')
    }
    
    if (this.hasWalletDropdownTarget) {
      this.walletDropdownTarget.classList.add('hidden')
    }
  }
  
  // Detect clicks outside of dropdowns to close them
  clickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.closeAllDropdowns()
    }
  }
  
  // Reset notification count (for demo purposes)
  resetNotificationCount() {
    this.notificationCountValue = 0
    
    if (this.hasNotificationCountTarget) {
      this.notificationCountTarget.textContent = '0'
      
      // Hide the notification badge if count is 0
      if (this.notificationCountValue === 0) {
        this.notificationCountTarget.classList.add('hidden')
      }
    }
  }
  
  // Handle scroll to add shadow and background to navbar
  handleScroll() {
    const scrolled = window.scrollY > 10
    
    if (scrolled && !this.scrolledValue) {
      this.element.classList.add('shadow-md')
      this.scrolledValue = true
    } else if (!scrolled && this.scrolledValue) {
      this.element.classList.remove('shadow-md')
      this.scrolledValue = false
    }
  }
  
  // Refresh wallet balance via API call
  refreshWalletBalance() {
    if (!this.hasWalletInfoTarget) return;
    
    fetch('/wallet/refresh_balance')
      .then(response => response.json())
      .then(data => {
        if (data.balance) {
          this.walletInfoTarget.textContent = data.formatted_balance
        }
      })
      .catch(error => console.error('Error fetching wallet balance:', error))
  }
}