import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    productId: Number,
    price: Number
  }
  
  connect() {
    // Hide sticky cart when user scrolls to the bottom of the page
    this.setupScrollListener()
  }
  
  disconnect() {
    // Clean up scroll listener
    window.removeEventListener('scroll', this.scrollHandler)
  }
  
  setupScrollListener() {
    this.scrollHandler = this.handleScroll.bind(this)
    window.addEventListener('scroll', this.scrollHandler)
  }
  
  handleScroll() {
    // Get the main add to cart button position
    const mainAddToCartButton = document.querySelector('[data-product-purchase-target="addToCartButton"]')
    if (!mainAddToCartButton) return
    
    const buttonRect = mainAddToCartButton.getBoundingClientRect()
    const windowHeight = window.innerHeight
    
    // If the main button is visible, hide the sticky cart
    if (buttonRect.top < windowHeight && buttonRect.bottom > 0) {
      this.element.classList.add('opacity-0', 'pointer-events-none')
    } else {
      this.element.classList.remove('opacity-0', 'pointer-events-none')
    }
  }
  
  addToCart(event) {
    event.preventDefault()
    
    // Add animation effect
    event.currentTarget.classList.add('animate-pulse')
    
    // Create form data
    const formData = new FormData()
    formData.append('product_id', this.productIdValue)
    formData.append('quantity', 1) // Default to 1 for the sticky cart
    
    // Submit the form via AJAX
    fetch('/cart/add', {
      method: 'POST',
      body: formData,
      headers: {
        'X-Requested-With': 'XMLHttpRequest',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      }
    })
    .then(response => {
      if (response.ok) {
        this.showToast('Product added to cart!')
        
        // Update cart count in header if it exists
        const cartCountElement = document.querySelector('.cart-count')
        if (cartCountElement) {
          const currentCount = parseInt(cartCountElement.textContent || '0')
          cartCountElement.textContent = currentCount + 1
        }
      } else {
        this.showToast('Error adding product to cart', 'error')
      }
      
      // Remove animation
      event.currentTarget.classList.remove('animate-pulse')
    })
    .catch(error => {
      console.error('Error:', error)
      this.showToast('Error adding product to cart', 'error')
      event.currentTarget.classList.remove('animate-pulse')
    })
  }
  
  showToast(message, type = 'success') {
    // Create toast element
    const toast = document.createElement('div')
    toast.className = `fixed bottom-20 left-1/2 transform -translate-x-1/2 z-50 px-4 py-2 rounded-lg shadow-lg transition-opacity duration-500 flex items-center ${
      type === 'success' ? 'bg-green-500 text-white' : 'bg-red-500 text-white'
    }`
    
    // Add icon based on type
    const icon = document.createElement('span')
    icon.className = 'mr-2'
    icon.innerHTML = type === 'success' 
      ? '<svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor"><path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" /></svg>'
      : '<svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor"><path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd" /></svg>'
    
    toast.appendChild(icon)
    
    // Add message
    const text = document.createElement('span')
    text.textContent = message
    toast.appendChild(text)
    
    // Add to DOM
    document.body.appendChild(toast)
    
    // Fade in
    setTimeout(() => {
      toast.style.opacity = '1'
    }, 10)
    
    // Remove after 3 seconds
    setTimeout(() => {
      toast.style.opacity = '0'
      setTimeout(() => {
        document.body.removeChild(toast)
      }, 500)
    }, 3000)
  }
}
