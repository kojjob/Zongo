import { Controller } from "@hotwired/stimulus"

// This controller handles coupon code application and removal
export default class extends Controller {
  static targets = ["input", "applyButton", "error", "success", "successTitle", "successMessage"]
  
  connect() {
    // Check if there's an existing coupon in the session
    if (this.hasCouponInSession()) {
      this.showAppliedCoupon()
    }
  }
  
  checkEnter(event) {
    if (event.key === "Enter") {
      event.preventDefault()
      this.apply()
    }
  }
  
  apply() {
    const code = this.inputTarget.value.trim()
    
    if (!code) {
      this.showError("Please enter a coupon code.")
      return
    }
    
    this.applyButtonTarget.disabled = true
    this.applyButtonTarget.innerHTML = '<svg class="animate-spin -ml-1 mr-2 h-4 w-4 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg> Applying...'
    
    fetch('/coupons/apply', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': this.getCSRFToken()
      },
      body: JSON.stringify({ code: code })
    })
    .then(response => response.json())
    .then(data => {
      this.applyButtonTarget.disabled = false
      this.applyButtonTarget.textContent = 'Apply'
      
      if (data.success) {
        this.hideError()
        this.successTitleTarget.textContent = 'Coupon applied!'
        this.successMessageTarget.textContent = `You saved ${data.formatted_discount} with this coupon.`
        this.showSuccess()
        
        // Update cart totals if they exist
        this.updateCartTotals(data)
        
        // Store coupon in session
        this.storeCouponInSession(code, data)
      } else {
        this.showError(data.message)
      }
    })
    .catch(error => {
      console.error('Error applying coupon:', error)
      this.applyButtonTarget.disabled = false
      this.applyButtonTarget.textContent = 'Apply'
      this.showError('An error occurred while applying the coupon. Please try again.')
    })
  }
  
  remove() {
    fetch('/coupons/remove', {
      method: 'DELETE',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': this.getCSRFToken()
      }
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        this.hideSuccess()
        this.inputTarget.value = ''
        
        // Update cart totals if they exist
        this.updateCartTotals(data)
        
        // Remove coupon from session
        this.removeCouponFromSession()
      }
    })
    .catch(error => {
      console.error('Error removing coupon:', error)
    })
  }
  
  showError(message) {
    this.errorTarget.textContent = message
    this.errorTarget.classList.remove('hidden')
    this.successTarget.classList.add('hidden')
  }
  
  hideError() {
    this.errorTarget.classList.add('hidden')
  }
  
  showSuccess() {
    this.successTarget.classList.remove('hidden')
    this.inputTarget.value = ''
  }
  
  hideSuccess() {
    this.successTarget.classList.add('hidden')
  }
  
  updateCartTotals(data) {
    // Update cart subtotal, discount, and total if elements exist
    const subtotalElement = document.getElementById('cart-subtotal')
    const discountElement = document.getElementById('cart-discount')
    const totalElement = document.getElementById('cart-total')
    
    if (totalElement) {
      totalElement.textContent = data.new_total
    }
    
    if (discountElement) {
      if (data.discount_amount && parseFloat(data.discount_amount) > 0) {
        discountElement.textContent = `-${data.formatted_discount}`
        discountElement.parentElement.classList.remove('hidden')
      } else {
        discountElement.parentElement.classList.add('hidden')
      }
    }
  }
  
  getCSRFToken() {
    return document.querySelector('meta[name="csrf-token"]').getAttribute('content')
  }
  
  hasCouponInSession() {
    return localStorage.getItem('couponCode') !== null
  }
  
  showAppliedCoupon() {
    const code = localStorage.getItem('couponCode')
    const discount = localStorage.getItem('couponDiscount')
    
    if (code && discount) {
      this.successTitleTarget.textContent = 'Coupon applied!'
      this.successMessageTarget.textContent = `You saved ${discount} with coupon: ${code}`
      this.showSuccess()
    }
  }
  
  storeCouponInSession(code, data) {
    localStorage.setItem('couponCode', code)
    localStorage.setItem('couponDiscount', data.formatted_discount)
  }
  
  removeCouponFromSession() {
    localStorage.removeItem('couponCode')
    localStorage.removeItem('couponDiscount')
  }
}
