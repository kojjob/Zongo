import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["quantity", "totalPrice", "addToCartButton", "quantityBadge", "wishlistButton"]

  connect() {
    this.updateTotal()
    this.updateQuantityBadge()

    // Check if product is in wishlist
    this.checkWishlistStatus()
  }

  decreaseQuantity(event) {
    event.preventDefault()
    const currentValue = parseInt(this.quantityTarget.value)
    if (currentValue > 1) {
      this.quantityTarget.value = currentValue - 1
      this.updateTotal()
      this.updateQuantityBadge()
    }
  }

  increaseQuantity(event) {
    event.preventDefault()
    const currentValue = parseInt(this.quantityTarget.value)
    const maxValue = parseInt(this.quantityTarget.max)
    if (currentValue < maxValue) {
      this.quantityTarget.value = currentValue + 1
      this.updateTotal()
      this.updateQuantityBadge()
    }
  }

  validateQuantity() {
    const value = parseInt(this.quantityTarget.value)
    const min = parseInt(this.quantityTarget.min)
    const max = parseInt(this.quantityTarget.max)

    if (isNaN(value) || value < min) {
      this.quantityTarget.value = min
    } else if (value > max) {
      this.quantityTarget.value = max
    }

    this.updateTotal()
    this.updateQuantityBadge()
  }

  updateTotal() {
    const quantity = parseInt(this.quantityTarget.value)
    const price = parseFloat(this.quantityTarget.dataset.price)
    const total = (price * quantity).toFixed(2)

    this.totalPriceTarget.textContent = `GHS ${total}`
  }

  updateQuantityBadge() {
    const quantity = parseInt(this.quantityTarget.value)
    this.quantityBadgeTarget.textContent = quantity
  }

  addToCart(event) {
    // Add animation effect
    this.addToCartButtonTarget.classList.add('animate-pulse')

    // Show a toast notification
    this.showToast('Product added to cart!')

    // We'll let the form submission continue normally
  }

  buyNow(event) {
    event.preventDefault()

    // First add to cart
    const formData = new FormData()
    formData.append('product_id', this.quantityTarget.form.querySelector('[name="product_id"]').value)
    formData.append('quantity', this.quantityTarget.value)

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
        // Redirect to checkout
        window.location.href = '/cart'
      } else {
        this.showToast('Error adding product to cart', 'error')
      }
    })
    .catch(error => {
      console.error('Error:', error)
      this.showToast('Error adding product to cart', 'error')
    })
  }

  toggleWishlist(event) {
    event.preventDefault()

    // Check if user is logged in
    const isLoggedIn = document.body.classList.contains('user-logged-in')

    if (!isLoggedIn) {
      // Redirect to login page
      window.location.href = '/users/sign_in'
      return
    }

    const productId = this.quantityTarget.form.querySelector('[name="product_id"]').value

    // Toggle wishlist state
    const isInWishlist = this.wishlistButtonTarget.classList.contains('wishlist-active')

    if (isInWishlist) {
      // Remove from wishlist
      this.removeFromWishlist(productId)
    } else {
      // Add to wishlist
      this.addToWishlist(productId)
    }
  }

  addToWishlist(productId) {
    // Animation while processing
    this.wishlistButtonTarget.classList.add('animate-pulse')

    // Simulate API call (replace with actual implementation)
    setTimeout(() => {
      // Update button state
      this.wishlistButtonTarget.classList.remove('animate-pulse')
      this.wishlistButtonTarget.classList.add('wishlist-active')
      this.wishlistButtonTarget.classList.add('text-red-500')
      this.wishlistButtonTarget.classList.add('border-red-500')

      // Update SVG to filled heart
      this.wishlistButtonTarget.innerHTML = `
        <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" viewBox="0 0 20 20" fill="currentColor">
          <path fill-rule="evenodd" d="M3.172 5.172a4 4 0 015.656 0L10 6.343l1.172-1.171a4 4 0 115.656 5.656L10 17.657l-6.828-6.829a4 4 0 010-5.656z" clip-rule="evenodd" />
        </svg>
      `

      this.showToast('Added to wishlist!')
    }, 500)
  }

  removeFromWishlist(productId) {
    // Animation while processing
    this.wishlistButtonTarget.classList.add('animate-pulse')

    // Simulate API call (replace with actual implementation)
    setTimeout(() => {
      // Update button state
      this.wishlistButtonTarget.classList.remove('animate-pulse')
      this.wishlistButtonTarget.classList.remove('wishlist-active')
      this.wishlistButtonTarget.classList.remove('text-red-500')
      this.wishlistButtonTarget.classList.remove('border-red-500')

      // Update SVG to outline heart
      this.wishlistButtonTarget.innerHTML = `
        <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" />
        </svg>
      `

      this.showToast('Removed from wishlist')
    }, 500)
  }

  checkWishlistStatus() {
    // This would normally check with the server if the product is in the user's wishlist
    // For now, we'll just assume it's not
    const isInWishlist = false

    if (isInWishlist) {
      this.wishlistButtonTarget.classList.add('wishlist-active')
      this.wishlistButtonTarget.classList.add('text-red-500')
      this.wishlistButtonTarget.classList.add('border-red-500')

      this.wishlistButtonTarget.innerHTML = `
        <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" viewBox="0 0 20 20" fill="currentColor">
          <path fill-rule="evenodd" d="M3.172 5.172a4 4 0 015.656 0L10 6.343l1.172-1.171a4 4 0 115.656 5.656L10 17.657l-6.828-6.829a4 4 0 010-5.656z" clip-rule="evenodd" />
        </svg>
      `
    }
  }

  showToast(message, type = 'success') {
    // Create toast element
    const toast = document.createElement('div')
    toast.className = `fixed top-4 right-4 z-50 px-4 py-2 rounded-lg shadow-lg transition-opacity duration-500 flex items-center ${
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
