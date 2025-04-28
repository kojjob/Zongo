import { Controller } from "@hotwired/stimulus"

// This controller handles the star rating functionality
export default class extends Controller {
  static targets = ["star", "input", "label"]
  
  connect() {
    // Set initial rating if available
    const initialRating = parseInt(this.inputTarget.value)
    if (initialRating) {
      this.updateStars(initialRating)
    }
    
    // Add hover effects
    this.starTargets.forEach((star, index) => {
      star.addEventListener('mouseenter', () => this.hoverStar(index + 1))
      star.addEventListener('mouseleave', () => this.resetStars())
    })
  }
  
  setRating(event) {
    const rating = parseInt(event.currentTarget.dataset.value)
    this.inputTarget.value = rating
    this.updateStars(rating)
    this.updateLabel(rating)
  }
  
  hoverStar(rating) {
    this.starTargets.forEach((star, index) => {
      if (index < rating) {
        star.classList.remove('text-gray-300', 'dark:text-gray-600')
        star.classList.add('text-yellow-400')
      } else {
        star.classList.remove('text-yellow-400')
        star.classList.add('text-gray-300', 'dark:text-gray-600')
      }
    })
    
    // Update label temporarily
    const currentRating = parseInt(this.inputTarget.value) || 0
    const tempLabel = this.getRatingLabel(rating)
    this.labelTarget.textContent = tempLabel
  }
  
  resetStars() {
    const currentRating = parseInt(this.inputTarget.value) || 0
    this.updateStars(currentRating)
    this.updateLabel(currentRating)
  }
  
  updateStars(rating) {
    this.starTargets.forEach((star, index) => {
      if (index < rating) {
        star.classList.remove('text-gray-300', 'dark:text-gray-600')
        star.classList.add('text-yellow-400')
      } else {
        star.classList.remove('text-yellow-400')
        star.classList.add('text-gray-300', 'dark:text-gray-600')
      }
    })
  }
  
  updateLabel(rating) {
    const label = rating ? this.getRatingLabel(rating) : 'Click to rate'
    this.labelTarget.textContent = label
  }
  
  getRatingLabel(rating) {
    const labels = ["", "Poor", "Fair", "Good", "Very Good", "Excellent"]
    return labels[rating] || ''
  }
}
