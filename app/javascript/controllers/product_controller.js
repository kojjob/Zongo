import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "featuredImage", 
    "zoomOverlay", 
    "zoomedImage", 
    "thumbnail", 
    "quantityInput", 
    "totalPrice"
  ]
  
  static values = {
    price: Number
  }
  
  connect() {
    this.updateTotalPrice()
  }
  
  // Image Gallery Methods
  selectThumbnail(event) {
    const src = event.currentTarget.dataset.src
    
    // Update main image and zoomed image
    this.featuredImageTarget.src = src
    this.zoomedImageTarget.src = src
    
    // Update active thumbnail
    this.thumbnailTargets.forEach(thumbnail => {
      thumbnail.classList.remove('ring-2', 'ring-primary-500')
    })
    event.currentTarget.classList.add('ring-2', 'ring-primary-500')
  }
  
  openZoom() {
    this.zoomOverlayTarget.classList.remove('hidden')
    document.body.style.overflow = 'hidden' // Prevent scrolling when zoomed
  }
  
  closeZoom() {
    this.zoomOverlayTarget.classList.add('hidden')
    document.body.style.overflow = '' // Restore scrolling
  }
  
  // Quantity Control Methods
  decreaseQuantity() {
    const currentValue = parseInt(this.quantityInputTarget.value)
    if (currentValue > 1) {
      this.quantityInputTarget.value = currentValue - 1
      this.updateTotalPrice()
    }
  }
  
  increaseQuantity() {
    const currentValue = parseInt(this.quantityInputTarget.value)
    const maxValue = parseInt(this.quantityInputTarget.getAttribute('max'))
    if (currentValue < maxValue) {
      this.quantityInputTarget.value = currentValue + 1
      this.updateTotalPrice()
    }
  }
  
  updateTotalPrice() {
    const quantity = parseInt(this.quantityInputTarget.value)
    const total = (this.priceValue * quantity).toFixed(2)
    this.totalPriceTarget.textContent = `Total: GHS ${total}`
  }
}
