import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "categoryCard", 
    "searchInput", 
    "searchResults", 
    "noResults", 
    "featuredBills", 
    "recentPayments",
    "billsContainer",
    "filterButton",
    "filterMenu",
    "savedBillsToggle"
  ]

  connect() {
    console.log("Bills controller connected")
    this.initializeAnimations()
    this.setupSearch()
    this.setupFilters()
    this.loadSavedBills()
  }

  // Initialize animations for the bill category cards
  initializeAnimations() {
    if (this.hasCategoryCardTarget) {
      this.categoryCardTargets.forEach((card, index) => {
        // Add staggered animation delay
        setTimeout(() => {
          card.classList.add('animate-in')
        }, 50 * index)
      })
    }
  }

  // Setup search functionality
  setupSearch() {
    if (this.hasSearchInputTarget) {
      this.searchInputTarget.addEventListener('input', this.handleSearch.bind(this))
    }
  }

  // Handle search input
  handleSearch() {
    const searchTerm = this.searchInputTarget.value.toLowerCase().trim()
    
    if (searchTerm.length < 2) {
      this.resetSearch()
      return
    }
    
    let matchFound = false
    
    // Filter bill categories
    this.categoryCardTargets.forEach(card => {
      const cardText = card.textContent.toLowerCase()
      const isMatch = cardText.includes(searchTerm)
      
      card.classList.toggle('hidden', !isMatch)
      
      if (isMatch) {
        matchFound = true
      }
    })
    
    // Show/hide no results message
    if (this.hasNoResultsTarget) {
      this.noResultsTarget.classList.toggle('hidden', matchFound)
    }
    
    // Hide featured bills section if searching
    if (this.hasFeaturedBillsTarget) {
      this.featuredBillsTarget.classList.add('hidden')
    }
  }
  
  // Reset search to show all categories
  resetSearch() {
    // Show all category cards
    this.categoryCardTargets.forEach(card => {
      card.classList.remove('hidden')
    })
    
    // Hide no results message
    if (this.hasNoResultsTarget) {
      this.noResultsTarget.classList.add('hidden')
    }
    
    // Show featured bills section
    if (this.hasFeaturedBillsTarget) {
      this.featuredBillsTarget.classList.remove('hidden')
    }
  }
  
  // Clear search input
  clearSearch() {
    this.searchInputTarget.value = ''
    this.resetSearch()
    this.searchInputTarget.focus()
  }
  
  // Setup filter functionality
  setupFilters() {
    // Close filter menu when clicking outside
    document.addEventListener('click', (event) => {
      if (this.hasFilterMenuTarget && this.hasFilterButtonTarget) {
        const isClickInside = this.filterButtonTarget.contains(event.target) || 
                             this.filterMenuTarget.contains(event.target)
        
        if (!isClickInside && !this.filterMenuTarget.classList.contains('hidden')) {
          this.toggleFilterMenu()
        }
      }
    })
  }
  
  // Toggle filter menu visibility
  toggleFilterMenu() {
    if (this.hasFilterMenuTarget) {
      this.filterMenuTarget.classList.toggle('hidden')
      
      // Add animation classes
      if (!this.filterMenuTarget.classList.contains('hidden')) {
        this.filterMenuTarget.classList.add('animate-in')
      } else {
        this.filterMenuTarget.classList.remove('animate-in')
      }
    }
  }
  
  // Filter bills by category
  filterByCategory(event) {
    const category = event.currentTarget.dataset.category
    
    // Update active state of filter buttons
    this.filterButtonTargets.forEach(button => {
      button.classList.toggle('active', button.dataset.category === category)
    })
    
    // Filter cards
    if (category === 'all') {
      this.categoryCardTargets.forEach(card => {
        card.classList.remove('hidden')
      })
    } else {
      this.categoryCardTargets.forEach(card => {
        const cardCategory = card.dataset.category
        card.classList.toggle('hidden', cardCategory !== category)
      })
    }
    
    // Close filter menu on mobile
    if (window.innerWidth < 768) {
      this.toggleFilterMenu()
    }
  }
  
  // Toggle saved bills view
  toggleSavedBills() {
    if (this.hasSavedBillsToggleTarget) {
      const isShowingSaved = this.savedBillsToggleTarget.checked
      
      if (isShowingSaved) {
        this.showSavedBillsOnly()
      } else {
        this.showAllBills()
      }
    }
  }
  
  // Show only saved bills
  showSavedBillsOnly() {
    const savedBills = JSON.parse(localStorage.getItem('savedBills') || '[]')
    
    this.categoryCardTargets.forEach(card => {
      const billId = card.dataset.billId
      const isSaved = savedBills.includes(billId)
      
      card.classList.toggle('hidden', !isSaved)
    })
  }
  
  // Show all bills
  showAllBills() {
    this.categoryCardTargets.forEach(card => {
      card.classList.remove('hidden')
    })
  }
  
  // Save a bill for quick access
  saveBill(event) {
    event.preventDefault()
    event.stopPropagation()
    
    const billCard = event.currentTarget.closest('[data-bills-target="categoryCard"]')
    const billId = billCard.dataset.billId
    
    // Get saved bills from localStorage
    const savedBills = JSON.parse(localStorage.getItem('savedBills') || '[]')
    
    // Toggle saved state
    const isSaved = savedBills.includes(billId)
    
    if (isSaved) {
      // Remove from saved bills
      const updatedSavedBills = savedBills.filter(id => id !== billId)
      localStorage.setItem('savedBills', JSON.stringify(updatedSavedBills))
      
      // Update UI
      event.currentTarget.classList.remove('text-yellow-500')
      event.currentTarget.classList.add('text-gray-400')
      billCard.classList.remove('is-saved')
    } else {
      // Add to saved bills
      savedBills.push(billId)
      localStorage.setItem('savedBills', JSON.stringify(savedBills))
      
      // Update UI
      event.currentTarget.classList.add('text-yellow-500')
      event.currentTarget.classList.remove('text-gray-400')
      billCard.classList.add('is-saved')
    }
  }
  
  // Load saved bills from localStorage
  loadSavedBills() {
    const savedBills = JSON.parse(localStorage.getItem('savedBills') || '[]')
    
    this.categoryCardTargets.forEach(card => {
      const billId = card.dataset.billId
      const isSaved = savedBills.includes(billId)
      
      if (isSaved) {
        card.classList.add('is-saved')
        const starButton = card.querySelector('.star-button')
        if (starButton) {
          starButton.classList.add('text-yellow-500')
          starButton.classList.remove('text-gray-400')
        }
      }
    })
  }
}
