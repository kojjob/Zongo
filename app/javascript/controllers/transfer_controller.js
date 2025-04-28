import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "accountNumber", 
    "accountName", 
    "amount", 
    "quickAmount", 
    "note", 
    "submitButton", 
    "summary", 
    "displayAmount", 
    "feeAmount", 
    "totalAmount", 
    "recipientName", 
    "recipientAccount",
    "pinInput",
    "pinContainer",
    "pinError",
    "transferForm",
    "loadingIndicator"
  ]

  connect() {
    console.log("Transfer controller connected")
    this.validateForm()
    this.setupPinInputs()
  }

  // Form validation
  validateForm() {
    const accountNumber = this.accountNumberTarget.value.trim()
    const amount = parseFloat(this.amountTarget.value) || 0
    
    // Check if all required fields are filled
    const isValid = accountNumber.length >= 5 && amount > 0
    
    // Update submit button state
    if (isValid) {
      this.submitButtonTarget.removeAttribute('disabled')
      this.submitButtonTarget.classList.remove('opacity-50', 'cursor-not-allowed')
      this.submitButtonTarget.classList.add('hover:shadow-xl', 'transform', 'hover:-translate-y-0.5')
    } else {
      this.submitButtonTarget.setAttribute('disabled', 'disabled')
      this.submitButtonTarget.classList.add('opacity-50', 'cursor-not-allowed')
      this.submitButtonTarget.classList.remove('hover:shadow-xl', 'transform', 'hover:-translate-y-0.5')
    }
    
    // Update payment summary
    if (amount > 0) {
      this.summaryTarget.classList.remove('hidden')
      
      // Update display values
      this.displayAmountTarget.textContent = `₵${amount.toFixed(2)}`
      
      // Calculate fee (1% of amount, minimum 1 GHS)
      const fee = Math.max(1, amount * 0.01)
      this.feeAmountTarget.textContent = `₵${fee.toFixed(2)}`
      
      // Calculate total
      const total = amount + fee
      this.totalAmountTarget.textContent = `₵${total.toFixed(2)}`
      
      // Update recipient info
      if (accountNumber) {
        this.recipientAccountTarget.textContent = accountNumber
      }
    } else {
      this.summaryTarget.classList.add('hidden')
    }
    
    return isValid
  }

  // Handle account number input
  accountNumberChanged() {
    this.validateForm()
    this.lookupAccountName()
  }

  // Handle amount input
  amountChanged() {
    this.validateForm()
    
    // Deselect any quick amount buttons
    this.quickAmountTargets.forEach(button => {
      button.classList.remove('bg-primary-100', 'dark:bg-primary-900/30', 'border-primary-300', 'dark:border-primary-700')
      button.classList.add('bg-white', 'dark:bg-gray-800', 'border-gray-200', 'dark:border-gray-700')
    })
  }

  // Handle quick amount selection
  selectQuickAmount(event) {
    const amount = event.currentTarget.dataset.amount
    
    // Update amount field
    this.amountTarget.value = amount
    
    // Update button styles
    this.quickAmountTargets.forEach(button => {
      button.classList.remove('bg-primary-100', 'dark:bg-primary-900/30', 'border-primary-300', 'dark:border-primary-700')
      button.classList.add('bg-white', 'dark:bg-gray-800', 'border-gray-200', 'dark:border-gray-700')
    })
    
    event.currentTarget.classList.remove('bg-white', 'dark:bg-gray-800', 'border-gray-200', 'dark:border-gray-700')
    event.currentTarget.classList.add('bg-primary-100', 'dark:bg-primary-900/30', 'border-primary-300', 'dark:border-primary-700')
    
    // Validate form
    this.validateForm()
  }

  // Lookup account name
  lookupAccountName() {
    const accountNumber = this.accountNumberTarget.value.trim()
    
    if (accountNumber.length < 5) {
      this.accountNameTarget.value = ''
      return
    }
    
    // Simulate account lookup with a timeout
    this.accountNameTarget.value = 'Looking up account...'
    
    clearTimeout(this.lookupTimeout)
    this.lookupTimeout = setTimeout(() => {
      // In a real app, this would be an API call
      // For demo purposes, we'll simulate a successful lookup
      if (accountNumber.length >= 5) {
        // Simulate different names based on account number
        const names = [
          'John Doe',
          'Jane Smith',
          'Kwame Mensah',
          'Ama Owusu',
          'Kofi Annan'
        ]
        const nameIndex = Math.floor(accountNumber.charAt(accountNumber.length - 1) % names.length)
        this.accountNameTarget.value = names[nameIndex]
        this.recipientNameTarget.textContent = names[nameIndex]
      } else {
        this.accountNameTarget.value = ''
      }
      
      this.validateForm()
    }, 800)
  }

  // Handle form submission
  submitTransfer(event) {
    event.preventDefault()
    
    const amount = parseFloat(this.amountTarget.value) || 0
    
    // Check if PIN verification is needed for large amounts
    if (amount >= 1000 && !this.pinVerified) {
      this.showPinVerification()
      return
    }
    
    // Submit the form
    this.processTransfer()
  }

  // Show PIN verification
  showPinVerification() {
    this.pinContainerTarget.classList.remove('hidden')
    this.pinInputTargets[0].focus()
  }

  // Setup PIN input fields
  setupPinInputs() {
    this.pinInputTargets.forEach((input, index) => {
      input.addEventListener('keydown', (e) => {
        if (e.key >= '0' && e.key <= '9') {
          this.pinInputTargets[index].value = ''
          setTimeout(() => {
            if (index < this.pinInputTargets.length - 1) {
              this.pinInputTargets[index + 1].focus()
            }
          }, 10)
        } else if (e.key === 'Backspace') {
          this.pinInputTargets[index].value = ''
          if (index > 0) {
            this.pinInputTargets[index - 1].focus()
          }
          setTimeout(() => {
            this.checkPin()
          }, 10)
        }
      })
      
      input.addEventListener('input', () => {
        if (input.value.length === 1) {
          if (index < this.pinInputTargets.length - 1) {
            this.pinInputTargets[index + 1].focus()
          }
          this.checkPin()
        }
      })
    })
  }

  // Check if PIN is complete and correct
  checkPin() {
    const pin = this.pinInputTargets.map(input => input.value).join('')
    
    if (pin.length === 4) {
      // In a real app, this would validate against the user's actual PIN
      // For demo purposes, we'll accept "1234" as the correct PIN
      if (pin === "1234") {
        this.pinVerified = true
        this.pinErrorTarget.classList.add('hidden')
        this.pinContainerTarget.classList.add('hidden')
        
        // Process the transfer
        this.processTransfer()
      } else {
        this.pinErrorTarget.classList.remove('hidden')
        this.pinInputTargets.forEach(input => {
          input.value = ''
        })
        this.pinInputTargets[0].focus()
      }
    }
  }

  // Cancel PIN verification
  cancelPin() {
    this.pinContainerTarget.classList.add('hidden')
    this.pinInputTargets.forEach(input => {
      input.value = ''
    })
    this.pinErrorTarget.classList.add('hidden')
  }

  // Process the transfer
  processTransfer() {
    // Show loading state
    this.loadingIndicatorTarget.classList.remove('hidden')
    this.submitButtonTarget.classList.add('hidden')
    
    // Simulate API call with timeout
    setTimeout(() => {
      // In a real app, this would submit the form to the server
      this.transferFormTarget.submit()
    }, 1500)
  }
}
