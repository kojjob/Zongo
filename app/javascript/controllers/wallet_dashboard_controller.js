import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "balanceDisplay",
    "maskedBalance",
    "eyeIcon",
    "eyeOffIcon",
    "moreActions",
    "balance",
    "refreshButton",
    "balanceContainer",
    "recentTransactions",
    "statValue"
  ]

  connect() {
    // Initialize animations for stat values
    if (this.hasStatValueTarget) {
      this.animateStatValues()
    }
  }

  // Toggle balance visibility
  toggleBalance() {
    this.balanceDisplayTarget.classList.toggle('hidden')
    this.maskedBalanceTarget.classList.toggle('hidden')
    this.eyeIconTarget.classList.toggle('hidden')
    this.eyeOffIconTarget.classList.toggle('hidden')
  }

  // Toggle more actions visibility
  toggleMoreActions() {
    this.moreActionsTarget.classList.toggle('hidden')
  }

  // Copy account ID to clipboard
  copyAccountId(event) {
    const accountId = event.currentTarget.dataset.accountId
    navigator.clipboard.writeText(accountId).then(() => {
      // Show tooltip or notification
      const button = event.currentTarget
      const originalHTML = button.innerHTML

      // Change to checkmark icon
      button.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" /></svg>'

      // Revert after 2 seconds
      setTimeout(() => {
        button.innerHTML = originalHTML
      }, 2000)
    })
  }

  // Refresh wallet balance with loading state
  refreshBalance() {
    if (!this.hasBalanceTarget || !this.hasRefreshButtonTarget) return

    // Show loading state
    this.refreshButtonTarget.classList.add('animate-spin')

    // Add loading overlay to balance container if it exists
    if (this.hasBalanceContainerTarget) {
      const loadingOverlay = document.createElement('div')
      loadingOverlay.classList.add('content-loading-overlay')
      loadingOverlay.innerHTML = `
        <div class="flex flex-col items-center">
          <div class="teal-spinner spinner mb-3"></div>
          <p class="text-sm font-medium text-white">Refreshing balance...</p>
        </div>
      `
      this.balanceContainerTarget.classList.add('relative')
      this.balanceContainerTarget.appendChild(loadingOverlay)
    }

    // Fetch updated balance
    fetch('/api/wallet/balance', {
      method: 'GET',
      headers: {
        'Accept': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      }
    })
    .then(response => response.json())
    .then(data => {
      // Update the balance with animation
      this.balanceTarget.classList.add('opacity-0')

      setTimeout(() => {
        this.balanceTarget.textContent = data.formatted_balance
        this.balanceTarget.classList.remove('opacity-0')
        this.balanceTarget.classList.add('fade-in')

        // Remove loading states
        this.refreshButtonTarget.classList.remove('animate-spin')

        // Remove loading overlay if it exists
        if (this.hasBalanceContainerTarget) {
          const overlay = this.balanceContainerTarget.querySelector('.content-loading-overlay')
          if (overlay) {
            overlay.classList.add('animate-fadeOut')
            setTimeout(() => {
              overlay.remove()
            }, 300)
          }
        }

        // Update stat values if they exist
        if (data.stats) {
          this.updateStatValues(data.stats)
        }
      }, 300)
    })
    .catch(error => {
      console.error('Error refreshing balance:', error)
      this.refreshButtonTarget.classList.remove('animate-spin')

      // Remove loading overlay if it exists
      if (this.hasBalanceContainerTarget) {
        const overlay = this.balanceContainerTarget.querySelector('.content-loading-overlay')
        if (overlay) overlay.remove()
      }

      // Show error notification
      this.showNotification('Error refreshing balance. Please try again.', 'error')
    })
  }

  // Refresh transactions with loading state
  refreshTransactions() {
    if (!this.hasRecentTransactionsTarget) return

    // Show loading state
    const loadingHTML = `
      <div class="p-6 flex flex-col items-center justify-center">
        <div class="teal-spinner spinner mb-4"></div>
        <p class="text-gray-600 dark:text-gray-400">Loading transactions...</p>
      </div>
    `

    // Add loading state with fade effect
    this.recentTransactionsTarget.classList.add('opacity-50', 'transition-opacity', 'duration-300')

    // Fetch updated transactions
    fetch('/api/wallet/recent_transactions', {
      method: 'GET',
      headers: {
        'Accept': 'text/html',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      }
    })
    .then(response => response.text())
    .then(html => {
      // Add loading bar at the top
      const loadingBar = document.createElement('div')
      loadingBar.classList.add('loading-bar', 'absolute', 'top-0', 'left-0', 'right-0')
      this.recentTransactionsTarget.parentElement.classList.add('relative')
      this.recentTransactionsTarget.parentElement.prepend(loadingBar)

      // Update with a slight delay for visual feedback
      setTimeout(() => {
        this.recentTransactionsTarget.innerHTML = html
        this.recentTransactionsTarget.classList.remove('opacity-50')

        // Remove loading bar after animation completes
        setTimeout(() => {
          loadingBar.remove()
        }, 2000)
      }, 500)
    })
    .catch(error => {
      console.error('Error refreshing transactions:', error)
      this.recentTransactionsTarget.classList.remove('opacity-50')

      // Show error notification
      this.showNotification('Error refreshing transactions. Please try again.', 'error')
    })
  }

  // Animate stat values on load
  animateStatValues() {
    this.statValueTargets.forEach(element => {
      const value = parseFloat(element.dataset.value || 0)
      const duration = 1500
      const frameDuration = 1000 / 60
      const totalFrames = Math.round(duration / frameDuration)
      const currencySymbol = element.textContent.charAt(0)

      let frame = 0
      const countTo = value

      // Start with zero
      element.textContent = currencySymbol + '0.00'

      // Animate to the target value
      const counter = setInterval(() => {
        frame++
        const progress = frame / totalFrames
        const currentCount = countTo * progress

        if (progress >= 1) {
          clearInterval(counter)
          element.textContent = currencySymbol + countTo.toFixed(2)
        } else {
          element.textContent = currencySymbol + currentCount.toFixed(2)
        }
      }, frameDuration)
    })
  }

  // Update stat values with animation
  updateStatValues(stats) {
    if (!this.hasStatValueTarget) return

    this.statValueTargets.forEach(element => {
      const key = element.dataset.key
      if (stats[key] !== undefined) {
        const value = parseFloat(stats[key])
        const currencySymbol = element.textContent.charAt(0)

        // Animate to new value
        const currentValue = parseFloat(element.textContent.substring(1))
        const duration = 1000
        const frameDuration = 1000 / 60
        const totalFrames = Math.round(duration / frameDuration)

        let frame = 0
        const startValue = currentValue
        const changeInValue = value - startValue

        const counter = setInterval(() => {
          frame++
          const progress = frame / totalFrames
          const currentCount = startValue + changeInValue * progress

          if (progress >= 1) {
            clearInterval(counter)
            element.textContent = currencySymbol + value.toFixed(2)
          } else {
            element.textContent = currencySymbol + currentCount.toFixed(2)
          }
        }, frameDuration)
      }
    })
  }

  // Show notification
  showNotification(message, type = 'info') {
    const notification = document.createElement('div')
    notification.classList.add(
      'fixed', 'bottom-4', 'right-4', 'p-4', 'rounded-lg', 'shadow-lg',
      'flex', 'items-center', 'z-50', 'animate-fadeIn'
    )

    // Set colors based on type
    if (type === 'error') {
      notification.classList.add('bg-red-500', 'text-white')
    } else if (type === 'success') {
      notification.classList.add('bg-green-500', 'text-white')
    } else {
      notification.classList.add('bg-blue-500', 'text-white')
    }

    // Add icon based on type
    let icon = ''
    if (type === 'error') {
      icon = '<svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>'
    } else if (type === 'success') {
      icon = '<svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" /></svg>'
    } else {
      icon = '<svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>'
    }

    notification.innerHTML = `
      ${icon}
      <span>${message}</span>
      <button class="ml-4 text-white" onclick="this.parentElement.remove()">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
        </svg>
      </button>
    `

    document.body.appendChild(notification)

    // Auto-remove after 5 seconds
    setTimeout(() => {
      notification.classList.add('animate-fadeOut')
      setTimeout(() => {
        notification.remove()
      }, 300)
    }, 5000)
  }
}
