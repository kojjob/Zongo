import { Controller } from "@hotwired/stimulus"

/**
 * Transactions Filter Controller
 * 
 * Handles the transaction history filter functionality:
 * - Validates date range inputs
 * - Auto-submits the form when certain filters change
 * - Resets filters to default values
 */
export default class extends Controller {
  static targets = ["startDate", "endDate"]
  
  connect() {
    // Initialize with current form state
    this.validateDates()
  }
  
  /**
   * Validate that the start date is not after the end date
   */
  validateDates() {
    if (!this.hasStartDateTarget || !this.hasEndDateTarget) return
    
    const startDate = new Date(this.startDateTarget.value)
    const endDate = new Date(this.endDateTarget.value)
    
    // If start date is after end date, adjust end date
    if (startDate > endDate) {
      this.endDateTarget.value = this.startDateTarget.value
    }
    
    // Ensure end date is not in the future
    const today = new Date()
    today.setHours(23, 59, 59, 999)
    
    if (endDate > today) {
      this.endDateTarget.value = this.formatDate(today)
    }
  }
  
  /**
   * Format a date as YYYY-MM-DD for input fields
   */
  formatDate(date) {
    return date.toISOString().split('T')[0]
  }
  
  /**
   * Automatically submit the form when dropdown filters change
   */
  submitOnChange(event) {
    const form = event.currentTarget.closest('form')
    if (form) {
      form.requestSubmit()
    }
  }
  
  /**
   * Apply all filters by submitting the form
   */
  applyFilters(event) {
    // First validate the dates
    this.validateDates()
  }
  
  /**
   * Reset all filters to default values
   */
  resetFilters(event) {
    event.preventDefault()
    
    const form = event.currentTarget.closest('form')
    if (!form) return
    
    // Reset type and status dropdowns to empty (all)
    const typeSelect = form.querySelector('select[name="type"]')
    const statusSelect = form.querySelector('select[name="status"]')
    
    if (typeSelect) typeSelect.value = ''
    if (statusSelect) statusSelect.value = ''
    
    // Reset date range to last 30 days
    if (this.hasStartDateTarget && this.hasEndDateTarget) {
      const endDate = new Date()
      const startDate = new Date()
      startDate.setDate(startDate.getDate() - 30)
      
      this.startDateTarget.value = this.formatDate(startDate)
      this.endDateTarget.value = this.formatDate(endDate)
    }
    
    // Submit the form with reset values
    form.requestSubmit()
  }
}
