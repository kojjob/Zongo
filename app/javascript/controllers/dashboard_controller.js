import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "balance",
    "balanceContainer",
    "refreshButton",
    "recentTransactions",
    "quickActionsPanel",
    "notificationsPanel",
    "profileDropdown",
    "transactionModal",
    "categoryTab",
    "securityLevel",
    "securityChart",
    "featureCard",
    "shortcutsModal"
  ]

  connect() {
    console.log("Dashboard controller connected")
    this.setupAnimations()
    this.initializeParticles()
    this.initializeEventListeners()
  }

  // Initialize floating particles animation
  initializeParticles() {
    // Add floating animation to particles
    const particles = document.querySelectorAll('.particle-1, .particle-2, .particle-3')
    particles.forEach((particle, index) => {
      if (particle) {
        // Set random initial positions
        const randomX = Math.floor(Math.random() * 80) + 10 // 10% to 90% of container width
        const randomY = Math.floor(Math.random() * 80) + 10 // 10% to 90% of container height

        particle.style.left = `${randomX}%`
        particle.style.top = `${randomY}%`
      }
    })
  }

  // Initialize event listeners for interactive elements
  initializeEventListeners() {
    // Add event listeners for category tabs
    if (this.hasCategoryTabTarget) {
      this.categoryTabTargets.forEach(tab => {
        tab.addEventListener('click', this.switchCategory.bind(this))
      })
    }

    // Add hover effects to feature cards
    if (this.hasFeatureCardTarget) {
      this.featureCardTargets.forEach(card => {
        card.addEventListener('mouseenter', () => {
          card.classList.add('transform', 'scale-105')
        })
        card.addEventListener('mouseleave', () => {
          card.classList.remove('transform', 'scale-105')
        })
      })
    }
  }

  // Switch between categories
  switchCategory(event) {
    if (this.hasCategoryTabTarget) {
      // Remove active class from all tabs
      this.categoryTabTargets.forEach(tab => {
        tab.classList.remove('bg-white', 'dark:bg-gray-700', 'shadow-sm', 'text-gray-900', 'dark:text-white')
        tab.classList.add('text-gray-600', 'dark:text-gray-400')
      })

      // Add active class to clicked tab
      const clickedTab = event.currentTarget
      clickedTab.classList.remove('text-gray-600', 'dark:text-gray-400')
      clickedTab.classList.add('bg-white', 'dark:bg-gray-700', 'shadow-sm', 'text-gray-900', 'dark:text-white')
    }
  }

  // Toggle balance visibility
  toggleBalance() {
    this.balanceContainerTarget.classList.add('animate-pulse')

    // Get the current balance display
    const balanceElem = this.balanceTarget
    const currentValue = balanceElem.textContent
    const isHidden = currentValue.includes('•')

    // Toggle between masked and actual balance
    if (isHidden) {
      // Make AJAX call to get the actual balance
      fetch('/api/wallet/balance', {
        method: 'GET',
        headers: {
          'Accept': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        }
      })
      .then(response => response.json())
      .then(data => {
        balanceElem.textContent = data.formatted_balance
        // Remove animation class after update
        setTimeout(() => {
          this.balanceContainerTarget.classList.remove('animate-pulse')
        }, 300)
      })
      .catch(error => {
        console.error('Error fetching balance:', error)
        this.balanceContainerTarget.classList.remove('animate-pulse')
      })
    } else {
      // Mask the balance with dots
      balanceElem.textContent = '•••••'

      // Remove animation class after update
      setTimeout(() => {
        this.balanceContainerTarget.classList.remove('animate-pulse')
      }, 300)
    }
  }

  // Refresh balance with visual feedback
  refreshBalance() {
    // Add a spinning animation to the refresh button
    this.refreshButtonTarget.classList.add("animate-spin")

    // Make AJAX call to refresh the balance
    fetch('/api/wallet/refresh_balance', {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      }
    })
    .then(response => response.json())
    .then(data => {
      // Stop the spinning animation
      this.refreshButtonTarget.classList.remove("animate-spin")

      // Update the balance with a visual effect
      this.balanceTarget.classList.add("animate-pulse")
      this.balanceTarget.textContent = data.formatted_balance

      // Remove animation class after update
      setTimeout(() => {
        this.balanceTarget.classList.remove("animate-pulse")
      }, 1000)
    })
    .catch(error => {
      console.error('Error refreshing balance:', error)
      this.refreshButtonTarget.classList.remove("animate-spin")
    })
  }

  // Toggle quick actions panel visibility
  toggleQuickActions() {
    const panel = this.quickActionsPanelTarget

    // Hide other panels if they're open
    if (this.hasNotificationsPanelTarget && !this.notificationsPanelTarget.classList.contains('hidden')) {
      this.toggleNotifications()
    }

    if (this.hasProfileDropdownTarget && !this.profileDropdownTarget.classList.contains('hidden')) {
      this.toggleProfileDropdown()
    }

    // Close transaction modal if it's open
    if (this.hasTransactionModalTarget && !this.transactionModalTarget.classList.contains('hidden')) {
      this.closeTransactionModal()
    }

    if (panel.classList.contains('hidden')) {
      // Show panel with animation
      panel.classList.remove('hidden')
      panel.classList.add('animate-fadeIn')

      // Remove animation class after completed
      setTimeout(() => {
        panel.classList.remove('animate-fadeIn')
      }, 500)
    } else {
      // Hide panel with animation
      panel.classList.add('animate-fadeOut')

      // After animation completes, hide the element
      setTimeout(() => {
        panel.classList.add('hidden')
        panel.classList.remove('animate-fadeOut')
      }, 300)
    }
  }

  // Toggle notifications panel visibility
  toggleNotifications() {
    const panel = this.notificationsPanelTarget

    // Hide other panels if they're open
    if (!this.quickActionsPanelTarget.classList.contains('hidden')) {
      this.toggleQuickActions()
    }

    if (this.hasProfileDropdownTarget && !this.profileDropdownTarget.classList.contains('hidden')) {
      this.toggleProfileDropdown()
    }

    // Close transaction modal if it's open
    if (this.hasTransactionModalTarget && !this.transactionModalTarget.classList.contains('hidden')) {
      this.closeTransactionModal()
    }

    if (panel.classList.contains('hidden')) {
      // Show panel with animation
      panel.classList.remove('hidden')
      panel.classList.add('animate-fadeIn')

      // Remove animation class after completed
      setTimeout(() => {
        panel.classList.remove('animate-fadeIn')
      }, 500)
    } else {
      // Hide panel with animation
      panel.classList.add('animate-fadeOut')

      // After animation completes, hide the element
      setTimeout(() => {
        panel.classList.add('hidden')
        panel.classList.remove('animate-fadeOut')
      }, 300)
    }
  }

  // Toggle profile dropdown visibility
  toggleProfileDropdown() {
    const dropdown = this.profileDropdownTarget

    // Hide other panels if they're open
    if (!this.quickActionsPanelTarget.classList.contains('hidden')) {
      this.toggleQuickActions()
    }

    if (this.hasNotificationsPanelTarget && !this.notificationsPanelTarget.classList.contains('hidden')) {
      this.toggleNotifications()
    }

    // Close transaction modal if it's open
    if (this.hasTransactionModalTarget && !this.transactionModalTarget.classList.contains('hidden')) {
      this.closeTransactionModal()
    }

    if (dropdown.classList.contains('hidden')) {
      // Show dropdown with animation
      dropdown.classList.remove('hidden')
      dropdown.classList.add('animate-fadeIn')

      // Add event listener to close dropdown when clicking outside
      document.addEventListener('click', this.closeProfileDropdown = (e) => {
        if (!dropdown.contains(e.target) && !e.target.closest('[data-action*="dashboard#toggleProfileDropdown"]')) {
          this.toggleProfileDropdown()
          document.removeEventListener('click', this.closeProfileDropdown)
        }
      })

      // Remove animation class after completed
      setTimeout(() => {
        dropdown.classList.remove('animate-fadeIn')
      }, 300)
    } else {
      // Hide dropdown with animation
      dropdown.classList.add('animate-fadeOut')

      // Remove click outside listener
      document.removeEventListener('click', this.closeProfileDropdown)

      // After animation completes, hide the element
      setTimeout(() => {
        dropdown.classList.add('hidden')
        dropdown.classList.remove('animate-fadeOut')
      }, 200)
    }
  }

  // Show transaction details modal
  showTransactionDetails(event) {
    event.preventDefault()

    // Get transaction ID from data attribute
    const transactionId = event.currentTarget.dataset.transactionId

    // Hide other panels if they're open
    if (!this.quickActionsPanelTarget.classList.contains('hidden')) {
      this.toggleQuickActions()
    }

    if (this.hasNotificationsPanelTarget && !this.notificationsPanelTarget.classList.contains('hidden')) {
      this.toggleNotifications()
    }

    if (this.hasProfileDropdownTarget && !this.profileDropdownTarget.classList.contains('hidden')) {
      this.toggleProfileDropdown()
    }

    // Create modal container if it doesn't exist
    if (!this.hasTransactionModalTarget) {
      const modalContainer = document.createElement('div')
      modalContainer.setAttribute('data-dashboard-target', 'transactionModal')
      modalContainer.classList.add('fixed', 'inset-0', 'z-50', 'bg-black/50', 'backdrop-blur-sm', 'flex', 'items-center', 'justify-center', 'p-2', 'sm:p-4', 'hidden')
      document.body.appendChild(modalContainer)
      this.transactionModalTarget = modalContainer
    }

    // Show enhanced loading state with skeleton UI
    this.transactionModalTarget.innerHTML = `
      <div class="bg-white dark:bg-gray-800 rounded-xl shadow-xl dark:shadow-2xl max-w-4xl w-full max-h-[95vh] sm:max-h-[90vh] overflow-hidden flex flex-col border border-gray-100 dark:border-gray-700">
        <div class="bg-gradient-to-r from-teal-500/10 to-emerald-500/10 dark:from-teal-500/20 dark:to-emerald-500/20 p-6 border-b border-gray-200 dark:border-gray-700">
          <div class="flex items-center justify-between">
            <div class="flex items-center">
              <div class="skeleton w-12 h-12 rounded-full mr-3"></div>
              <div>
                <div class="skeleton w-48 h-6 rounded mb-2"></div>
                <div class="skeleton w-32 h-4 rounded"></div>
              </div>
            </div>
            <div class="text-right">
              <div class="skeleton w-32 h-8 rounded mb-2"></div>
              <div class="skeleton w-24 h-4 rounded"></div>
            </div>
          </div>
        </div>

        <div class="p-6">
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <div class="skeleton w-40 h-6 rounded mb-4"></div>
              <div class="space-y-3">
                ${Array(6).fill().map(() => `
                  <div class="flex justify-between border-b border-gray-200 dark:border-gray-700 pb-2">
                    <div class="skeleton w-24 h-4 rounded"></div>
                    <div class="skeleton w-32 h-4 rounded"></div>
                  </div>
                `).join('')}
              </div>
            </div>

            <div>
              <div class="skeleton w-40 h-6 rounded mb-4"></div>
              <div class="space-y-4 mb-6">
                <div class="bg-gray-50 dark:bg-gray-700 rounded-lg p-3">
                  <div class="skeleton w-20 h-4 rounded mb-2"></div>
                  <div class="flex items-center">
                    <div class="skeleton w-8 h-8 rounded-full mr-3"></div>
                    <div>
                      <div class="skeleton w-32 h-4 rounded mb-1"></div>
                      <div class="skeleton w-24 h-3 rounded"></div>
                    </div>
                  </div>
                </div>

                <div class="bg-gray-50 dark:bg-gray-700 rounded-lg p-3">
                  <div class="skeleton w-20 h-4 rounded mb-2"></div>
                  <div class="flex items-center">
                    <div class="skeleton w-8 h-8 rounded-full mr-3"></div>
                    <div>
                      <div class="skeleton w-32 h-4 rounded mb-1"></div>
                      <div class="skeleton w-24 h-3 rounded"></div>
                    </div>
                  </div>
                </div>
              </div>

              <div class="skeleton w-40 h-6 rounded mb-4"></div>
              <div class="space-y-3">
                ${Array(3).fill().map(() => `
                  <div class="flex">
                    <div class="flex flex-col items-center mr-3">
                      <div class="skeleton w-3 h-3 rounded-full"></div>
                      <div class="skeleton w-0.5 h-8"></div>
                    </div>
                    <div>
                      <div class="skeleton w-32 h-4 rounded mb-1"></div>
                      <div class="skeleton w-24 h-3 rounded"></div>
                    </div>
                  </div>
                `).join('')}
              </div>
            </div>
          </div>

          <div class="mt-6 flex justify-end space-x-3">
            <div class="skeleton w-32 h-10 rounded-lg"></div>
            <div class="skeleton w-24 h-10 rounded-lg"></div>
          </div>
        </div>

        <div class="absolute inset-0 flex items-center justify-center bg-white/80 dark:bg-gray-800/80 backdrop-blur-sm">
          <div class="flex flex-col items-center">
            <div class="teal-spinner spinner mb-4"></div>
            <p class="text-gray-700 dark:text-gray-300 text-sm sm:text-base font-medium">Loading transaction details...</p>
          </div>
        </div>
      </div>
    `

    // Show modal with animation
    this.transactionModalTarget.classList.remove('hidden')
    this.transactionModalTarget.classList.add('animate-fadeIn')

    // Add event listener to close modal when clicking outside
    this.transactionModalTarget.addEventListener('click', this.handleModalOutsideClick = (e) => {
      if (e.target === this.transactionModalTarget) {
        this.closeTransactionModal()
      }
    })

    // Prevent scrolling on body
    document.body.style.overflow = 'hidden'

    // Fetch transaction details
    fetch(`/dashboard/transaction_details/${transactionId}`, {
      headers: {
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest'
      }
    })
    .then(response => {
      if (!response.ok) {
        throw new Error('Network response was not ok')
      }
      return response.json()
    })
    .then(data => {
      // Update modal content
      this.transactionModalTarget.innerHTML = `
        <div class="bg-white dark:bg-gray-800 rounded-xl shadow-xl dark:shadow-2xl max-w-4xl w-full max-h-[95vh] sm:max-h-[90vh] overflow-hidden flex flex-col border border-gray-100 dark:border-gray-700">
          <div class="overflow-y-auto">
            ${data.html}
          </div>
        </div>
      `

      // Add event listener to close button
      const closeButton = this.transactionModalTarget.querySelector('.close-modal-btn')
      if (closeButton) {
        closeButton.addEventListener('click', () => {
          this.closeTransactionModal()
        })
      }
    })
    .catch(error => {
      console.error('Error fetching transaction details:', error)

      // Show enhanced error state with animation
      this.transactionModalTarget.innerHTML = `
        <div class="bg-white dark:bg-gray-800 rounded-xl shadow-xl dark:shadow-2xl max-w-4xl w-full p-4 sm:p-8 text-center border border-gray-100 dark:border-gray-700 relative overflow-hidden">
          <div class="absolute top-0 left-0 right-0 h-1 bg-red-500"></div>

          <div class="py-6">
            <div class="w-20 h-20 mx-auto mb-6 relative">
              <div class="absolute inset-0 bg-red-100 dark:bg-red-900/30 rounded-full pulse-animation"></div>
              <div class="absolute inset-0 flex items-center justify-center">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-10 w-10 text-red-500 dark:text-red-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              </div>
            </div>

            <h3 class="text-xl sm:text-2xl font-bold text-gray-900 dark:text-white mb-2 sm:mb-3">Error Loading Transaction</h3>
            <p class="text-sm sm:text-base text-gray-600 dark:text-gray-300 mb-6 sm:mb-8 max-w-md mx-auto">
              We couldn't load the transaction details. This could be due to a network issue or the transaction may no longer exist.
            </p>

            <div class="flex flex-col sm:flex-row items-center justify-center gap-3">
              <button type="button" class="close-modal-btn w-full sm:w-auto px-5 py-2.5 bg-gray-200 dark:bg-gray-700 hover:bg-gray-300 dark:hover:bg-gray-600 text-gray-800 dark:text-gray-200 text-sm font-medium rounded-lg transition-colors duration-300 border border-transparent dark:border-gray-600 shadow-sm dark:shadow-md flex items-center justify-center">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                </svg>
                Close
              </button>

              <button type="button" class="w-full sm:w-auto px-5 py-2.5 bg-gradient-to-r from-teal-500 to-emerald-500 hover:from-teal-600 hover:to-emerald-600 text-white text-sm font-medium rounded-lg transition-colors duration-300 shadow-sm dark:shadow-md flex items-center justify-center"
                      onclick="window.location.reload()">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                </svg>
                Refresh Page
              </button>
            </div>
          </div>
        </div>
      `

      // Add event listener to close button
      const closeButton = this.transactionModalTarget.querySelector('.close-modal-btn')
      if (closeButton) {
        closeButton.addEventListener('click', () => {
          this.closeTransactionModal()
        })
      }
    })
  }

  // Close transaction details modal
  closeTransactionModal() {
    if (!this.hasTransactionModalTarget) return

    // Hide modal with animation
    this.transactionModalTarget.classList.add('animate-fadeOut')

    // Remove event listeners
    this.transactionModalTarget.removeEventListener('click', this.handleModalOutsideClick)

    // After animation completes, hide the element
    setTimeout(() => {
      this.transactionModalTarget.classList.add('hidden')
      this.transactionModalTarget.classList.remove('animate-fadeOut')
      this.transactionModalTarget.innerHTML = ''

      // Re-enable scrolling on body
      document.body.style.overflow = ''
    }, 300)
  }

  // Refresh transactions list with enhanced loading state
  refreshTransactions() {
    if (!this.hasRecentTransactionsTarget) return

    // Show loading state with skeleton UI
    this.recentTransactionsTarget.innerHTML = `
      <div class="p-6">
        <div class="flex items-center justify-between mb-6">
          <div class="skeleton w-48 h-6 rounded"></div>
          <div class="skeleton w-32 h-8 rounded-lg"></div>
        </div>

        <div class="space-y-4">
          ${Array(3).fill().map(() => `
            <div class="bg-white dark:bg-gray-800 rounded-lg p-4 border border-gray-200 dark:border-gray-700">
              <div class="flex items-center justify-between">
                <div class="flex items-center">
                  <div class="skeleton w-10 h-10 rounded-full mr-3"></div>
                  <div>
                    <div class="skeleton w-32 h-4 mb-2 rounded"></div>
                    <div class="skeleton w-24 h-3 rounded"></div>
                  </div>
                </div>
                <div class="skeleton w-20 h-8 rounded-lg"></div>
              </div>
            </div>
          `).join('')}
        </div>
      </div>
    `

    // Add loading bar at the top
    const loadingBar = document.createElement('div')
    loadingBar.classList.add('loading-bar', 'absolute', 'top-0', 'left-0', 'right-0', 'z-10')
    this.recentTransactionsTarget.parentElement.classList.add('relative')
    this.recentTransactionsTarget.parentElement.prepend(loadingBar)

    // Make AJAX call to refresh transactions
    fetch('/api/transactions/recent', {
      method: 'GET',
      headers: {
        'Accept': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      }
    })
    .then(response => {
      if (!response.ok) {
        throw new Error('Network response was not ok')
      }
      return response.text()
    })
    .then(html => {
      // Update with a slight delay for visual feedback
      setTimeout(() => {
        // Fade out current content
        this.recentTransactionsTarget.classList.add('opacity-0', 'transition-opacity', 'duration-200')

        // After fade out, update content and fade in
        setTimeout(() => {
          this.recentTransactionsTarget.innerHTML = html
          this.recentTransactionsTarget.classList.remove('opacity-0')

          // Remove loading bar after animation completes
          setTimeout(() => {
            if (loadingBar) loadingBar.remove()
          }, 1000)
        }, 200)
      }, 800) // Minimum loading time for better UX
    })
    .catch(error => {
      console.error('Error refreshing transactions:', error)

      // Show error state
      this.recentTransactionsTarget.innerHTML = `
        <div class="p-8 flex flex-col items-center justify-center text-center">
          <div class="w-16 h-16 rounded-full bg-red-100 dark:bg-red-900/30 flex items-center justify-center mb-4">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-8 w-8 text-red-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
          <h3 class="text-lg font-bold text-gray-900 dark:text-white mb-2">Error Loading Transactions</h3>
          <p class="text-gray-600 dark:text-gray-400 mb-4">We couldn't load your transactions. Please try again.</p>
          <button type="button" class="px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg font-medium"
                  data-action="dashboard#refreshTransactions">
            <i class="fas fa-sync-alt mr-2"></i>
            Try Again
          </button>
        </div>
      `

      // Remove loading bar
      if (loadingBar) loadingBar.remove()
    })
  }

  // Setup animations and visual enhancements
  setupAnimations() {
    // Add custom animations for better visual feedback
    const style = document.createElement('style')
    style.textContent = `
      @keyframes fadeIn {
        from { opacity: 0; transform: translateY(10px); }
        to { opacity: 1; transform: translateY(0); }
      }

      @keyframes fadeOut {
        from { opacity: 1; transform: translateY(0); }
        to { opacity: 0; transform: translateY(10px); }
      }

      @keyframes float {
        0% { transform: translateY(0px); }
        50% { transform: translateY(-10px); }
        100% { transform: translateY(0px); }
      }

      @keyframes pulse-slow {
        0% { opacity: 0.4; }
        50% { opacity: 0.8; }
        100% { opacity: 0.4; }
      }

      @keyframes pulse-slower {
        0% { opacity: 0.3; }
        50% { opacity: 0.6; }
        100% { opacity: 0.3; }
      }

      .animate-fadeIn {
        animation: fadeIn 0.3s ease-out forwards;
      }

      .animate-fadeOut {
        animation: fadeOut 0.3s ease-in forwards;
      }

      .animate-float {
        animation: float 6s ease-in-out infinite;
      }

      .animate-pulse-slow {
        animation: pulse-slow 4s ease-in-out infinite;
      }

      .animate-pulse-slower {
        animation: pulse-slower 6s ease-in-out infinite;
      }
    `
    document.head.appendChild(style)

    // Animate progress bars on load
    this.animateProgressBars()

    // Add scroll animations for better engagement
    this.setupScrollAnimations()

    // Initialize security chart if present
    this.initializeSecurityChart()
  }

  // Initialize security chart with animation
  initializeSecurityChart() {
    if (this.hasSecurityChartTarget && this.hasSecurityLevelTarget) {
      // Get the current security level
      const securityLevel = parseInt(this.securityLevelTarget.textContent || "0", 10)

      // Animate the security chart
      const circumference = 2 * Math.PI * 45 // 2πr where r=45
      const fullOffset = circumference
      const targetOffset = circumference - (securityLevel / 100) * circumference

      // Start with empty chart
      this.securityChartTarget.setAttribute('stroke-dashoffset', fullOffset)

      // Animate to the target value
      setTimeout(() => {
        this.securityChartTarget.style.transition = "stroke-dashoffset 1.5s ease-out"
        this.securityChartTarget.setAttribute('stroke-dashoffset', targetOffset)
      }, 500)
    }
  }

  // Update security level visualization
  updateSecurityLevel(level) {
    if (this.hasSecurityLevelTarget && this.hasSecurityChartTarget) {
      // Update the security level text with animation
      this.securityLevelTarget.classList.add('animate-pulse')

      setTimeout(() => {
        // Update the security level text
        this.securityLevelTarget.textContent = `${level}%`
        this.securityLevelTarget.classList.remove('animate-pulse')

        // Update the chart
        const circumference = 2 * Math.PI * 45 // 2πr where r=45
        const offset = circumference - (level / 100) * circumference

        this.securityChartTarget.style.transition = "stroke-dashoffset 1s ease-out"
        this.securityChartTarget.setAttribute('stroke-dashoffset', offset)

        // Update the gradient based on level
        let gradient = 'securityGradientLow' // Default for low security

        if (level >= 70) {
          gradient = 'securityGradientHigh'
        } else if (level >= 40) {
          gradient = 'securityGradient'
        }

        this.securityChartTarget.setAttribute('stroke', `url(#${gradient})`)
      }, 300)
    }
  }

  // Animate progress bars for visual appeal
  animateProgressBars() {
    // Find all progress bars
    const progressBars = document.querySelectorAll("[data-progress-bar]")

    progressBars.forEach(bar => {
      // Get the target width from the data attribute
      const targetWidth = bar.getAttribute("data-target-width") || "0%"

      // Start with zero width
      bar.style.width = "0%"

      // Animate to target width
      setTimeout(() => {
        bar.style.transition = "width 1s ease-out"
        bar.style.width = targetWidth
      }, 300)
    })
  }

  // Setup animations triggered by scrolling
  setupScrollAnimations() {
    // Create an Intersection Observer
    const observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        // If the element is in the viewport
        if (entry.isIntersecting) {
          // Add animation class
          entry.target.classList.add('animate-fadeIn')
          // Unobserve after animation
          observer.unobserve(entry.target)
        }
      })
    }, { threshold: 0.1 }) // Trigger when 10% of the element is visible

    // Observe all sections that should animate on scroll
    document.querySelectorAll('.mb-8').forEach(section => {
      observer.observe(section)
    })
  }
}