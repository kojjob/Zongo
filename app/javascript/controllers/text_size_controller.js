import { Controller } from "@hotwired/stimulus"

// Controller for handling text size changes
export default class extends Controller {
  static targets = ["slider", "value"]
  static values = {
    url: { type: String, default: '/user_settings/update_appearance' }
  }

  connect() {
    console.log("Text size controller connected")
    
    // Initialize the slider value
    if (this.hasSliderTarget) {
      this.sliderTarget.addEventListener('input', this.updateTextSize.bind(this))
      this.updateTextSize()
    }
  }
  
  updateTextSize() {
    const size = this.sliderTarget.value
    console.log(`Setting text size to: ${size}`)
    
    // Update the value display if it exists
    if (this.hasValueTarget) {
      this.valueTarget.textContent = this.getSizeLabel(size)
    }
    
    // Apply the text size to the document
    this.applyTextSize(size)
    
    // Debounce the save operation
    if (this.saveTimeout) {
      clearTimeout(this.saveTimeout)
    }
    
    this.saveTimeout = setTimeout(() => {
      this.saveTextSize(size)
    }, 500)
  }
  
  getSizeLabel(size) {
    const labels = {
      '1': 'Small',
      '2': 'Medium Small',
      '3': 'Medium (Default)',
      '4': 'Medium Large',
      '5': 'Large'
    }
    
    return labels[size] || `Size ${size}`
  }
  
  applyTextSize(size) {
    // Remove any existing text size classes
    document.documentElement.classList.remove('text-size-1', 'text-size-2', 'text-size-3', 'text-size-4', 'text-size-5')
    
    // Add the new text size class
    document.documentElement.classList.add(`text-size-${size}`)
    
    // Store in localStorage for persistence
    localStorage.setItem('textSize', size)
  }
  
  saveTextSize(size) {
    // Create form data
    const formData = new FormData()
    formData.append('user[settings][text_size]', size)
    
    // Send AJAX request
    fetch(this.urlValue, {
      method: 'PATCH',
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest'
      },
      body: formData
    })
    .then(response => {
      if (!response.ok) {
        throw new Error('Network response was not ok')
      }
      return response.json()
    })
    .then(data => {
      console.log('Text size saved:', data)
      
      // Show a success message
      this.showNotification(`Text size set to ${this.getSizeLabel(size)}`, 'success')
    })
    .catch(error => {
      console.error('Error saving text size:', error)
      
      // Show an error message
      this.showNotification('Failed to save text size', 'error')
    })
  }
  
  showNotification(message, type = 'info') {
    // Create notification element
    const notification = document.createElement('div')
    notification.className = `fixed bottom-4 right-4 px-6 py-3 rounded-lg shadow-lg z-50 ${
      type === 'success' ? 'bg-green-500 text-white' : 
      type === 'error' ? 'bg-red-500 text-white' : 
      'bg-blue-500 text-white'
    }`
    notification.style.transition = 'all 0.3s ease-in-out'
    notification.style.opacity = '0'
    notification.style.transform = 'translateY(20px)'
    
    // Add icon based on type
    const icon = document.createElement('i')
    icon.className = `fas fa-${
      type === 'success' ? 'check-circle' : 
      type === 'error' ? 'exclamation-circle' : 
      'info-circle'
    } mr-2`
    notification.appendChild(icon)
    
    // Add message text
    const text = document.createTextNode(message)
    notification.appendChild(text)
    
    // Add to DOM
    document.body.appendChild(notification)
    
    // Trigger animation
    setTimeout(() => {
      notification.style.opacity = '1'
      notification.style.transform = 'translateY(0)'
    }, 10)
    
    // Remove after delay
    setTimeout(() => {
      notification.style.opacity = '0'
      notification.style.transform = 'translateY(20px)'
      
      setTimeout(() => {
        document.body.removeChild(notification)
      }, 300)
    }, 3000)
  }
}
