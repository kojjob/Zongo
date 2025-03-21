import { Controller } from "@hotwired/stimulus"

/**
 * Transaction Form Controller
 * 
 * Handles the interactive elements of the transaction form:
 * - Updates the transaction summary as values change
 * - Allows selecting payment methods with better UX
 * - Validates form inputs
 * - Manages the submit button state
 */
export default class extends Controller {
  static targets = [
    "amount", 
    "methodRadio", 
    "methodsContainer",
    "displayAmount", 
    "displayTotal",
    "submitButton",
    "recipient",
    "recentRecipients"
  ]
  
  connect() {
    // Initialize the form with default values
    this.updateTotal()
    this.validateForm()
    
    // If there's a pre-selected payment method, highlight the container
    this.highlightSelectedMethod()
  }
  
  /**
   * Update the total amount display when amount changes
   */
  updateTotal() {
    if (!this.hasAmountTarget || !this.hasDisplayAmountTarget || !this.hasDisplayTotalTarget) return
    
    const amount = parseFloat(this.amountTarget.value) || 0
    const fee = 0 // For now, we're not charging fees
    const total = amount + fee
    
    // Format with currency symbol from data attribute or default to $
    const currencySymbol = this.amountTarget.dataset.currencySymbol || '₵'
    
    this.displayAmountTarget.textContent = `${currencySymbol}${amount.toFixed(2)}`
    this.displayTotalTarget.textContent = `${currencySymbol}${total.toFixed(2)}`
  }
  
  /**
   * Set the amount to the maximum available balance
   */
  setMaxAmount(event) {
    if (!this.hasAmountTarget) return
    
    const maxAmount = parseFloat(this.amountTarget.max) || 0
    this.amountTarget.value = maxAmount.toFixed(2)
    this.updateTotal()
  }
  
  /**
   * Improve payment method selection UX by allowing clicking anywhere in the container
   */
  selectMethod(event) {
    // Find the container element that was clicked
    const container = event.currentTarget
    
    // Find the radio button inside this container
    const radio = container.querySelector('input[type="radio"]')
    if (!radio) return
    
    // Select this radio button
    radio.checked = true
    
    // Highlight the selected method
    this.highlightSelectedMethod()
    
    // Validate the form
    this.validateForm()
  }
  
  /**
   * Select a recipient from the recent recipients list
   */
  selectRecipient(event) {
    if (!this.hasRecipientTarget) return
    
    const button = event.currentTarget
    const recipient = button.dataset.recipient
    
    this.recipientTarget.value = recipient
    
    // Highlight the selected recipient
    if (this.hasRecentRecipientsTarget) {
      this.recentRecipientsTarget.querySelectorAll('button').forEach(btn => {
        btn.classList.remove('bg-primary-100', 'dark:bg-primary-900', 'text-primary-800', 'dark:text-primary-200')
        btn.classList.add('bg-gray-100', 'dark:bg-gray-700', 'text-gray-800', 'dark:text-gray-200')
      })
      
      button.classList.remove('bg-gray-100', 'dark:bg-gray-700', 'text-gray-800', 'dark:text-gray-200')
      button.classList.add('bg-primary-100', 'dark:bg-primary-900', 'text-primary-800', 'dark:text-primary-200')
    }
    
    this.validateForm()
  }
  
  /**
   * Highlight the container of the selected payment method
   */
  highlightSelectedMethod() {
    if (!this.hasMethodsContainerTarget || !this.hasMethodRadioTarget) return
    
    // Reset all containers
    const containers = this.methodsContainerTarget.querySelectorAll('div[data-action*="transaction-form#selectMethod"]')
    containers.forEach(container => {
      container.classList.remove('border-primary-500', 'dark:border-primary-500')
      container.classList.add('border-gray-200', 'dark:border-gray-700')
    })
    
    // Find selected radio and highlight its container
    this.methodRadioTargets.forEach(radio => {
      if (radio.checked) {
        const container = radio.closest('div[data-action*="transaction-form#selectMethod"]')
        if (container) {
          container.classList.remove('border-gray-200', 'dark:border-gray-700')
          container.classList.add('border-primary-500', 'dark:border-primary-500')
        }
      }
    })
  }
  
  /**
   * Validate the form and update UI
   */
  validateForm() {
    if (!this.hasSubmitButtonTarget) return
    
    let isValid = true
    
    // Validate amount
    if (this.hasAmountTarget) {
      const amount = parseFloat(this.amountTarget.value) || 0
      if (amount <= 0) {
        isValid = false
      }
      
      // Check if amount exceeds max (if max is specified)
      if (this.amountTarget.max && amount > parseFloat(this.amountTarget.max)) {
        isValid = false
      }
    }
    
    // Validate payment method selection
    if (this.hasMethodRadioTarget) {
      const methodSelected = this.methodRadioTargets.some(radio => radio.checked)
      if (!methodSelected) {
        isValid = false
      }
    }
    
    // Validate recipient (for transfers)
    if (this.hasRecipientTarget && this.recipientTarget.required) {
      if (!this.recipientTarget.value.trim()) {
        isValid = false
      }
    }
    
    // Update submit button state
    this.submitButtonTarget.disabled = !isValid
    
    // Update submit button appearance
    if (isValid) {
      this.submitButtonTarget.classList.remove('opacity-50', 'cursor-not-allowed')
    } else {
      this.submitButtonTarget.classList.add('opacity-50', 'cursor-not-allowed')
    }
    
    return isValid
  }
}
