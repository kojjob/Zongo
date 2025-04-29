import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="loan-application"
export default class extends Controller {
  static targets = [
    "loanType", 
    "amount", 
    "termDays", 
    "interestRate", 
    "processingFee", 
    "totalDue", 
    "monthlyPayment",
    "dueDate",
    "loanTypeInfo",
    "loanTypeDescription"
  ]
  
  connect() {
    console.log("Loan application controller connected")
    this.updateCalculations()
    
    // Set up event listeners
    if (this.hasLoanTypeTarget) {
      this.loanTypeTarget.addEventListener('change', this.updateLoanTypeInfo.bind(this))
      this.updateLoanTypeInfo()
    }
    
    if (this.hasAmountTarget) {
      this.amountTarget.addEventListener('input', this.updateCalculations.bind(this))
    }
    
    if (this.hasTermDaysTarget) {
      this.termDaysTarget.addEventListener('input', this.updateCalculations.bind(this))
    }
  }
  
  disconnect() {
    // Clean up event listeners
    if (this.hasLoanTypeTarget) {
      this.loanTypeTarget.removeEventListener('change', this.updateLoanTypeInfo.bind(this))
    }
    
    if (this.hasAmountTarget) {
      this.amountTarget.removeEventListener('input', this.updateCalculations.bind(this))
    }
    
    if (this.hasTermDaysTarget) {
      this.termDaysTarget.removeEventListener('input', this.updateCalculations.bind(this))
    }
  }
  
  updateLoanTypeInfo() {
    const loanType = this.loanTypeTarget.value
    
    // Update term days based on loan type
    if (this.hasTermDaysTarget) {
      switch(loanType) {
        case 'microloan':
          this.termDaysTarget.value = 30
          break
        case 'emergency':
          this.termDaysTarget.value = 14
          break
        case 'installment':
          this.termDaysTarget.value = 90
          break
        case 'business':
          this.termDaysTarget.value = 180
          break
        case 'agricultural':
          this.termDaysTarget.value = 180
          break
        case 'salary_advance':
          this.termDaysTarget.value = 30
          break
      }
    }
    
    // Update loan type description
    if (this.hasLoanTypeDescriptionTarget) {
      const descriptions = {
        microloan: "Small, short-term loans for immediate needs with quick approval.",
        emergency: "Quick access loans for urgent situations with minimal documentation.",
        installment: "Longer-term loans with scheduled repayments for larger expenses.",
        business: "Loans for small business owners to support growth and operations.",
        agricultural: "Specialized loans for farmers to support agricultural activities.",
        salary_advance: "Short-term loans based on your salary with automatic repayment."
      }
      
      this.loanTypeDescriptionTarget.textContent = descriptions[loanType] || ""
    }
    
    // Show the relevant loan type info section
    if (this.hasLoanTypeInfoTarget) {
      const allInfoElements = document.querySelectorAll('[data-loan-type-info]')
      allInfoElements.forEach(el => {
        el.classList.add('hidden')
      })
      
      const infoElement = document.querySelector(`[data-loan-type-info="${loanType}"]`)
      if (infoElement) {
        infoElement.classList.remove('hidden')
      }
    }
    
    this.updateCalculations()
  }
  
  updateCalculations() {
    if (!this.hasAmountTarget || !this.hasLoanTypeTarget) return
    
    const amount = parseFloat(this.amountTarget.value) || 0
    const loanType = this.loanTypeTarget.value
    const termDays = parseInt(this.hasTermDaysTarget ? this.termDaysTarget.value : 30) || 30
    
    // Calculate interest rate based on loan type
    let interestRate = 0
    switch(loanType) {
      case 'microloan':
        interestRate = 5.0
        break
      case 'emergency':
        interestRate = 8.0
        break
      case 'installment':
        interestRate = 15.0
        break
      case 'business':
        interestRate = 18.0
        break
      case 'agricultural':
        interestRate = 12.0
        break
      case 'salary_advance':
        interestRate = 4.0
        break
      default:
        interestRate = 10.0
    }
    
    // Calculate processing fee
    let processingFeeRate = 0
    switch(loanType) {
      case 'microloan':
        processingFeeRate = 0.01
        break
      case 'emergency':
        processingFeeRate = 0.02
        break
      case 'installment':
        processingFeeRate = 0.015
        break
      case 'business':
        processingFeeRate = 0.02
        break
      case 'agricultural':
        processingFeeRate = 0.01
        break
      case 'salary_advance':
        processingFeeRate = 0.005
        break
      default:
        processingFeeRate = 0.015
    }
    
    const processingFee = amount * processingFeeRate
    
    // Calculate interest amount (simple interest)
    const interestAmount = (amount * interestRate / 100) * (termDays / 365.0)
    
    // Calculate total due
    const totalDue = amount + interestAmount + processingFee
    
    // Calculate monthly payment (for installment loans)
    let monthlyPayment = totalDue
    if (loanType === 'installment' || loanType === 'business' || loanType === 'agricultural') {
      const numInstallments = Math.max(Math.floor(termDays / 30), 1)
      monthlyPayment = totalDue / numInstallments
    }
    
    // Calculate due date
    const dueDate = new Date()
    dueDate.setDate(dueDate.getDate() + termDays)
    
    // Update UI
    if (this.hasInterestRateTarget) {
      this.interestRateTarget.textContent = interestRate.toFixed(2) + '%'
    }
    
    if (this.hasProcessingFeeTarget) {
      this.processingFeeTarget.textContent = 'GHS ' + processingFee.toFixed(2)
    }
    
    if (this.hasTotalDueTarget) {
      this.totalDueTarget.textContent = 'GHS ' + totalDue.toFixed(2)
    }
    
    if (this.hasMonthlyPaymentTarget) {
      this.monthlyPaymentTarget.textContent = 'GHS ' + monthlyPayment.toFixed(2)
    }
    
    if (this.hasDueDateTarget) {
      this.dueDateTarget.textContent = dueDate.toLocaleDateString('en-GB', {
        day: 'numeric',
        month: 'long',
        year: 'numeric'
      })
    }
  }
}
