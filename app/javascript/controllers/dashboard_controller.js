import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="dashboard"
export default class extends Controller {
  static targets = [
    "balance", 
    "refreshButton", 
    "recentTransactions", 
    "statValue"
  ]
  
  connect() {
    console.log("Dashboard controller connected")
    this.animateStatValues()
  }
  
  refreshBalance() {
    // Add a spinning animation to the refresh button
    this.refreshButtonTarget.classList.add("animate-spin")
    
    // Make an AJAX request to get the latest balance
    fetch("/dashboard/refresh_balance", {
      headers: {
        "Accept": "application/json",
        "X-Requested-With": "XMLHttpRequest"
      }
    })
    .then(response => response.json())
    .then(data => {
      // Update the balance display
      this.balanceTarget.textContent = data.balance
      
      // Stop the spinning animation
      this.refreshButtonTarget.classList.remove("animate-spin")
      
      // Flash the balance to indicate it's been updated
      this.balanceTarget.classList.add("animate-pulse")
      setTimeout(() => {
        this.balanceTarget.classList.remove("animate-pulse")
      }, 1000)
    })
    .catch(error => {
      console.error("Error refreshing balance:", error)
      this.refreshButtonTarget.classList.remove("animate-spin")
    })
  }
  
  refreshTransactions() {
    // Add a loading state
    this.recentTransactionsTarget.classList.add("opacity-50")
    
    // Fetch updated transactions
    fetch("/dashboard/refresh_transactions", {
      headers: {
        "Accept": "text/vnd.turbo-stream.html",
        "X-Requested-With": "XMLHttpRequest"
      }
    })
    .then(response => response.text())
    .then(html => {
      // Turbo will handle the update automatically
      this.recentTransactionsTarget.classList.remove("opacity-50")
    })
    .catch(error => {
      console.error("Error refreshing transactions:", error)
      this.recentTransactionsTarget.classList.remove("opacity-50")
    })
  }
  
  animateStatValues() {
    // Animate all stat values with a counting effect
    if (this.hasStatValueTarget) {
      this.statValueTargets.forEach(statElement => {
        const finalValue = parseFloat(statElement.dataset.value || 0)
        const duration = 1500 // Animation duration in milliseconds
        const frameDuration = 16 // milliseconds per frame (roughly 60fps)
        const totalFrames = Math.round(duration / frameDuration)
        
        // Get currency symbol if present
        const text = statElement.textContent
        const currencySymbol = text.match(/^[^\d]*/)[0] || ''
        
        let currentFrame = 0
        const countTo = finalValue
        const increment = countTo / totalFrames
        
        const animate = () => {
          currentFrame++
          const value = Math.min(increment * currentFrame, countTo)
          statElement.textContent = `${currencySymbol}${value.toFixed(2)}`
          
          if (currentFrame < totalFrames) {
            requestAnimationFrame(animate)
          } else {
            statElement.textContent = `${currencySymbol}${finalValue.toFixed(2)}`
          }
        }
        
        animate()
      })
    }
  }
}