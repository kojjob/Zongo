import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["balance", "balanceContainer", "refreshButton", "recentTransactions", "quickActionsPanel"]

  connect() {
    console.log("Dashboard controller connected")
    this.setupAnimations()
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

  // Refresh transactions list
  refreshTransactions() {
    // Add loading state
    this.recentTransactionsTarget.classList.add("opacity-50")
    
    // Make AJAX call to refresh transactions
    fetch('/api/transactions/recent', {
      method: 'GET',
      headers: {
        'Accept': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      }
    })
    .then(response => response.text())
    .then(html => {
      // Update the transactions container
      this.recentTransactionsTarget.innerHTML = html
      
      // Remove loading state with small delay for visual feedback
      setTimeout(() => {
        this.recentTransactionsTarget.classList.remove("opacity-50")
      }, 300)
    })
    .catch(error => {
      console.error('Error refreshing transactions:', error)
      this.recentTransactionsTarget.classList.remove("opacity-50")
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
      
      .animate-fadeIn {
        animation: fadeIn 0.3s ease-out forwards;
      }
      
      .animate-fadeOut {
        animation: fadeOut 0.3s ease-in forwards;
      }
    `
    document.head.appendChild(style)
    
    // Animate progress bars on load
    this.animateProgressBars()
    
    // Add scroll animations for better engagement
    this.setupScrollAnimations()
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