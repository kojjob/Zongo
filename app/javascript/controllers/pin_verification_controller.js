import { Controller } from "@hotwired/stimulus"

// This controller handles PIN verification for transactions
export default class extends Controller {
  static targets = ["pinInput", "pinContainer", "transactionForm", "submitButton"]
  static values = {
    required: Boolean,
    amount: Number
  }
  
  connect() {
    // Check if PIN verification is required based on transaction amount or security settings
    if (this.requiredValue || this.isLargeTransaction()) {
      this.showPinVerification()
    }
  }
  
  // Check if this is a large transaction that requires PIN verification
  isLargeTransaction() {
    // The threshold for large transactions (could be dynamic based on wallet limits)
    const largeTransactionThreshold = 500
    return this.amountValue >= largeTransactionThreshold
  }
  
  // Show the PIN verification UI
  showPinVerification() {
    if (this.hasPinContainerTarget) {
      this.pinContainerTarget.classList.remove('hidden')
      
      // Make the PIN required
      if (this.hasPinInputTarget) {
        this.pinInputTarget.setAttribute('required', 'required')
        
        // Focus on the PIN input
        setTimeout(() => {
          this.pinInputTarget.focus()
        }, 100)
      }
      
      // Disable the submit button until PIN is entered
      if (this.hasSubmitButtonTarget) {
        this.submitButtonTarget.setAttribute('disabled', 'disabled')
      }
    }
  }
  
  // Hide the PIN verification UI
  hidePinVerification() {
    if (this.hasPinContainerTarget) {
      this.pinContainerTarget.classList.add('hidden')
      
      // Make the PIN not required
      if (this.hasPinInputTarget) {
        this.pinInputTarget.removeAttribute('required')
      }
      
      // Enable the submit button
      if (this.hasSubmitButtonTarget) {
        this.submitButtonTarget.removeAttribute('disabled')
      }
    }
  }
  
  // Validate PIN format (4-6 digits)
  validatePin() {
    if (!this.hasPinInputTarget) return
    
    const pin = this.pinInputTarget.value
    const isValid = /^\d{4,6}$/.test(pin)
    
    if (isValid) {
      this.pinInputTarget.classList.remove('border-red-500')
      this.pinInputTarget.classList.add('border-green-500')
      
      // Enable the submit button
      if (this.hasSubmitButtonTarget) {
        this.submitButtonTarget.removeAttribute('disabled')
      }
    } else {
      this.pinInputTarget.classList.remove('border-green-500')
      this.pinInputTarget.classList.add('border-red-500')
      
      // Disable the submit button
      if (this.hasSubmitButtonTarget) {
        this.submitButtonTarget.setAttribute('disabled', 'disabled')
      }
    }
  }
  
  // When user changes the transaction amount, determine if PIN is required
  updateAmount(event) {
    const newAmount = parseFloat(event.target.value) || 0
    this.amountValue = newAmount
    
    if (this.isLargeTransaction()) {
      this.showPinVerification()
    } else if (!this.requiredValue) {
      this.hidePinVerification()
    }
  }
  
  // Clear the PIN input (useful for security)
  clearPin() {
    if (this.hasPinInputTarget) {
      this.pinInputTarget.value = ''
      this.validatePin()
    }
  }
}
