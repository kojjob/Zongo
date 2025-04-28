import { Controller } from "@hotwired/stimulus"

// This controller handles the product form functionality
export default class extends Controller {
  static targets = ["digitalSection"]
  static values = { type: String }
  
  connect() {
    console.log("Product form controller connected")
    this.toggleDigitalSection()
    
    // Add event listener to the product type select
    const productTypeSelect = document.getElementById('product_product_type')
    if (productTypeSelect) {
      productTypeSelect.addEventListener('change', this.handleProductTypeChange.bind(this))
    }
  }
  
  handleProductTypeChange(event) {
    this.typeValue = event.target.value
    this.toggleDigitalSection()
  }
  
  toggleDigitalSection() {
    if (this.hasDigitalSectionTarget) {
      if (this.typeValue === 'digital') {
        this.digitalSectionTarget.classList.remove('hidden')
      } else {
        this.digitalSectionTarget.classList.add('hidden')
      }
    }
  }
}
