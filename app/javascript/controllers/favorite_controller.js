import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["icon", "count"]
  static values = {
    url: String,
    favorited: Boolean,
    count: Number
  }

  connect() {
    // Initialize state based on values
    this.updateIcon()
  }

  toggle(event) {
    event.preventDefault()
    
    // Show loading state
    this.element.classList.add("animate-pulse")
    
    // Send AJAX request to toggle favorite
    fetch(this.urlValue, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        "Accept": "application/json"
      },
      credentials: "same-origin"
    })
    .then(response => {
      if (!response.ok) {
        throw new Error("Network response was not ok")
      }
      return response.json()
    })
    .then(data => {
      // Update state based on response
      this.favoritedValue = data.favorited
      this.countValue = data.favorite_count
      
      // Update UI
      this.updateIcon()
      this.updateCount()
      
      // Show success state briefly
      this.element.classList.add(data.favorited ? "bg-red-500" : "bg-gray-500")
      this.element.classList.add("text-white")
      
      setTimeout(() => {
        this.element.classList.remove(data.favorited ? "bg-red-500" : "bg-gray-500")
        this.element.classList.remove("text-white")
      }, 300)
    })
    .catch(error => {
      console.error("Error toggling favorite:", error)
      
      // Show error state briefly
      this.element.classList.add("bg-red-100")
      
      setTimeout(() => {
        this.element.classList.remove("bg-red-100")
      }, 300)
    })
    .finally(() => {
      this.element.classList.remove("animate-pulse")
    })
  }
  
  updateIcon() {
    if (this.hasIconTarget) {
      if (this.favoritedValue) {
        // Show filled heart
        this.iconTarget.innerHTML = `
          <svg class="h-5 w-5 text-red-500" fill="currentColor" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" fill="currentColor"></path>
          </svg>
        `
      } else {
        // Show outline heart
        this.iconTarget.innerHTML = `
          <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"></path>
          </svg>
        `
      }
    }
  }
  
  updateCount() {
    if (this.hasCountTarget) {
      this.countTarget.textContent = this.countValue
    }
  }
}
