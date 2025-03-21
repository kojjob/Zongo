import { Controller } from "@hotwired/stimulus"

/**
 * Wallet Dashboard Controller
 * 
 * Adds interactive features to the wallet dashboard:
 * - Animated counters for statistics
 * - Balance refresh functionality
 * - Quick actions enhancements
 */
export default class extends Controller {
  static targets = [
    "balance", 
    "refreshButton", 
    "statValue",
    "recentTransactions"
  ]
  
  connect() {
    // Initialize animated counters
    if (this.hasStatValueTarget) {
      this.animateCounters()
    }
  }
  
  /**
   * Refresh wallet balance via AJAX
   */
  refreshBalance(event) {
    if (!this.hasBalanceTarget || !this.hasRefreshButtonTarget) return
    
    // Show loading state on button
    this.refreshButtonTarget.classList.add('animate-spin')
    this.refreshButtonTarget.disabled = true
    
    // Make AJAX request to get updated balance
    fetch('/wallet/refresh_balance', {
      method: 'GET',
      headers: {
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content || ''
      }
    })
    .then(response => response.json())
    .then(data => {
      // Update balance
      this.balanceTarget.textContent = data.formatted_balance
      
      // Show success indicator
      this.refreshButtonTarget.classList.remove('animate-spin')
      this.refreshButtonTarget.classList.add('text-green-500')
      
      // Reset after a delay
      setTimeout(() => {
        this.refreshButtonTarget.classList.remove('text-green-500')
        this.refreshButtonTarget.disabled = false
      }, 1500)
    })
    .catch(error => {
      console.error('Error refreshing balance:', error)
      
      // Show error indicator
      this.refreshButtonTarget.classList.remove('animate-spin')
      this.refreshButtonTarget.classList.add('text-red-500')
      
      // Reset after a delay
      setTimeout(() => {
        this.refreshButtonTarget.classList.remove('text-red-500')
        this.refreshButtonTarget.disabled = false
      }, 1500)
    })
  }
  
  /**
   * Animate counter statistics
   */
  animateCounters() {
    this.statValueTargets.forEach(element => {
      const targetValue = parseFloat(element.dataset.value || element.textContent)
      if (isNaN(targetValue)) return
      
      // Start from zero
      let startValue = 0
      
      // Get prefix and suffix if any
      const text = element.textContent
      const prefix = text.match(/^[^\d-.]*/)[0] || ''
      const suffix = text.match(/[^\d-.]*$/)[0] || ''
      
      // Determine if we need decimal places
      const isDecimal = targetValue % 1 !== 0
      const decimalPlaces = isDecimal ? 2 : 0
      
      // Set duration based on value (higher values = longer animation)
      const duration = Math.min(2000, Math.max(1000, targetValue * 10))
      
      // Animate the counter
      const startTime = performance.now()
      
      const updateCounter = (currentTime) => {
        // Calculate progress (0 to 1)
        const elapsed = currentTime - startTime
        const progress = Math.min(elapsed / duration, 1)
        
        // Apply easing function for smoother animation
        const easedProgress = this.easeOutQuad(progress)
        
        // Calculate current value
        const currentValue = startValue + (targetValue - startValue) * easedProgress
        
        // Update element text
        element.textContent = `${prefix}${currentValue.toFixed(decimalPlaces)}${suffix}`
        
        // Continue animation until complete
        if (progress < 1) {
          requestAnimationFrame(updateCounter)
        }
      }
      
      // Start animation
      requestAnimationFrame(updateCounter)
    })
  }
  
  /**
   * Easing function for smoother animations
   */
  easeOutQuad(x) {
    return 1 - (1 - x) * (1 - x)
  }
  
  /**
   * Refresh recent transactions list
   */
  refreshTransactions(event) {
    if (!this.hasRecentTransactionsTarget) return
    
    // Show loading state
    this.recentTransactionsTarget.classList.add('opacity-50')
    
    // Make AJAX request to refresh transactions
    fetch('/wallet/recent_transactions', {
      method: 'GET',
      headers: {
        'Accept': 'text/html',
        'X-Requested-With': 'XMLHttpRequest',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content || ''
      }
    })
    .then(response => response.text())
    .then(html => {
      // Update the transactions list with new HTML
      this.recentTransactionsTarget.innerHTML = html
      
      // Reset loading state
      this.recentTransactionsTarget.classList.remove('opacity-50')
    })
    .catch(error => {
      console.error('Error refreshing transactions:', error)
      this.recentTransactionsTarget.classList.remove('opacity-50')
    })
  }
}
