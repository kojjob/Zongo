import { Controller } from "@hotwired/stimulus"

// This controller handles the coupon form functionality
export default class extends Controller {
  static targets = ["codeInput"]
  
  connect() {
    console.log("Coupon form controller connected")
  }
  
  generateCode() {
    fetch('/admin/coupons/generate_code')
      .then(response => response.json())
      .then(data => {
        const codeInput = document.getElementById('coupon_code')
        if (codeInput) {
          codeInput.value = data.code
        }
      })
      .catch(error => {
        console.error('Error generating coupon code:', error)
      })
  }
}
