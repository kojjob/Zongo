import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="dynamic-navbar"
export default class extends Controller {
  static targets = [
    "container", 
    "mobileMenu", 
    "dropdown",
    "searchBar",
    "userMenu",
    "activeIndicator"
  ]
  
  static values = {
    scrolled: Boolean,
    transparent: Boolean,
    activeItem: String
  }
  
  connect() {
    console.log("Dynamic navbar controller connected")
    
    // Set initial scrolled state
    this.scrolledValue = window.scrollY > 50
    this.updateNavbarAppearance()
    
    // Add scroll event listener
    this.boundHandleScroll = this.handleScroll.bind(this)
    window.addEventListener('scroll', this.boundHandleScroll)
    
    // Initialize active item highlight
    this.highlightActiveItem()
  }
  
  disconnect() {
    window.removeEventListener('scroll', this.boundHandleScroll)
  }
  
  // Triggered when active item value changes
  activeItemValueChanged() {
    this.highlightActiveItem()
  }
  
  // Handle scroll event to update navbar appearance
  handleScroll() {
    const scrolled = window.scrollY > 50
    
    if (scrolled !== this.scrolledValue) {
      this.scrolledValue = scrolled
      this.updateNavbarAppearance()
    }
  }
  
  // Update navbar appearance based on scroll position
  updateNavbarAppearance() {
    if (this.hasContainerTarget) {
      if (this.scrolledValue) {
        this.containerTarget.classList.add('scrolled')
        
        // If navbar should become opaque when scrolled
        if (this.transparentValue) {
          this.containerTarget.classList.remove('bg-transparent')
          this.containerTarget.classList.add('bg-white', 'dark:bg-gray-900', 'shadow-md')
        }
      } else {
        this.containerTarget.classList.remove('scrolled')
        
        // If navbar should be transparent at top
        if (this.transparentValue) {
          this.containerTarget.classList.add('bg-transparent')
          this.containerTarget.classList.remove('bg-white', 'dark:bg-gray-900', 'shadow-md')
        }
      }
    }
  }
  
  // Toggle mobile menu visibility
  toggleMobileMenu(event) {
    event.preventDefault()
    
    if (this.hasMobileMenuTarget) {
      const isHidden = this.mobileMenuTarget.classList.contains('translate-x-full')
      
      if (isHidden) {
        // Show the menu
        this.mobileMenuTarget.classList.remove('translate-x-full')
        document.body.classList.add('overflow-hidden')
      } else {
        // Hide the menu
        this.mobileMenuTarget.classList.add('translate-x-full')
        document.body.classList.remove('overflow-hidden')
      }
    }
  }
  
  // Toggle dropdown visibility
  toggleDropdown(event) {
    event.preventDefault()
    
    const dropdown = event.currentTarget.nextElementSibling
    const isHidden = dropdown.classList.contains('hidden')
    
    // Close all other dropdowns first
    this.closeAllDropdowns()
    
    if (isHidden) {
      // Show dropdown
      dropdown.classList.remove('hidden')
      // Add animation
      setTimeout(() => {
        dropdown.classList.remove('opacity-0', 'scale-95', 'pointer-events-none')
        dropdown.classList.add('opacity-100', 'scale-100', 'pointer-events-auto')
      }, 10)
    }
  }
  
  // Close all dropdowns
  closeAllDropdowns() {
    const dropdowns = this.dropdownTargets
    
    dropdowns.forEach(dropdown => {
      dropdown.classList.add('opacity-0', 'scale-95', 'pointer-events-none')
      dropdown.classList.remove('opacity-100', 'scale-100', 'pointer-events-auto')
      
      setTimeout(() => {
        dropdown.classList.add('hidden')
      }, 150)
    })
  }
  
  // Close dropdowns when clicking outside
  clickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.closeAllDropdowns()
    }
  }
  
  // Toggle search bar visibility (mobile)
  toggleSearchBar(event) {
    event.preventDefault()
    
    if (this.hasSearchBarTarget) {
      this.searchBarTarget.classList.toggle('hidden')
      
      // Focus search input when visible
      if (!this.searchBarTarget.classList.contains('hidden')) {
        const searchInput = this.searchBarTarget.querySelector('input')
        if (searchInput) {
          setTimeout(() => searchInput.focus(), 100)
        }
      }
    }
  }
  
  // Toggle user menu dropdown
  toggleUserMenu(event) {
    event.preventDefault()
    
    if (this.hasUserMenuTarget) {
      const isHidden = this.userMenuTarget.classList.contains('hidden')
      
      // Close all other dropdowns first
      this.closeAllDropdowns()
      
      if (isHidden) {
        // Show user menu
        this.userMenuTarget.classList.remove('hidden')
        // Add animation
        setTimeout(() => {
          this.userMenuTarget.classList.remove('opacity-0', 'scale-95', 'pointer-events-none')
          this.userMenuTarget.classList.add('opacity-100', 'scale-100', 'pointer-events-auto')
        }, 10)
      } else {
        // Hide user menu
        this.userMenuTarget.classList.add('opacity-0', 'scale-95', 'pointer-events-none')
        this.userMenuTarget.classList.remove('opacity-100', 'scale-100', 'pointer-events-auto')
        
        setTimeout(() => {
          this.userMenuTarget.classList.add('hidden')
        }, 150)
      }
    }
  }
  
  // Highlight the active navigation item
  highlightActiveItem() {
    if (!this.hasActiveIndicatorTarget || !this.activeItemValue) return
    
    // Find the active navigation item
    const activeItem = this.element.querySelector(`[data-nav-id="${this.activeItemValue}"]`)
    
    if (activeItem) {
      // Position the active indicator
      const rect = activeItem.getBoundingClientRect()
      const parentRect = activeItem.parentElement.getBoundingClientRect()
      
      // Set indicator width and position
      this.activeIndicatorTarget.style.width = `${rect.width}px`
      this.activeIndicatorTarget.style.left = `${rect.left - parentRect.left}px`
      this.activeIndicatorTarget.classList.remove('opacity-0')
    } else {
      // Hide indicator if no active item
      this.activeIndicatorTarget.classList.add('opacity-0')
    }
  }
}
