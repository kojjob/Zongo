import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="pin"
export default class extends Controller {
  static targets = ["form", "currentPin", "newPin", "confirmPin", "currentPinSection", "error"]

  connect() {
    // Add event listeners for the toggle password buttons
    document.querySelectorAll('.toggle-password').forEach(button => {
      button.addEventListener('click', this.togglePasswordVisibility.bind(this))
    })
    
    // Add form submission handler
    if (this.hasFormTarget) {
      this.formTarget.addEventListener('submit', this.handleSubmit.bind(this))
    }
  }

  disconnect() {
    // Remove event listeners
    document.querySelectorAll('.toggle-password').forEach(button => {
      button.removeEventListener('click', this.togglePasswordVisibility.bind(this))
    })
    
    if (this.hasFormTarget) {
      this.formTarget.removeEventListener('submit', this.handleSubmit.bind(this))
    }
  }

  togglePasswordVisibility(event) {
    const button = event.currentTarget
    const targetId = button.dataset.target
    const input = document.getElementById(targetId)
    
    if (input) {
      // Toggle between password and text type
      const type = input.getAttribute('type') === 'password' ? 'text' : 'password'
      input.setAttribute('type', type)
      
      // Toggle the eye icon
      const icon = button.querySelector('svg')
      if (type === 'text') {
        icon.outerHTML = this.eyeOffIcon()
      } else {
        icon.outerHTML = this.eyeIcon()
      }
    }
  }
  
  handleSubmit(event) {
    event.preventDefault()
    
    // Clear previous errors
    if (this.hasErrorTarget) {
      this.errorTarget.textContent = ''
      this.errorTarget.classList.add('hidden')
    }
    
    // Get PIN values
    const newPin = this.newPinTarget.value
    const confirmPin = this.confirmPinTarget.value
    
    // Validate PINs
    if (newPin.length !== 4 || !/^\d{4}$/.test(newPin)) {
      this.showError('PIN must be exactly 4 digits')
      return
    }
    
    if (newPin !== confirmPin) {
      this.showError('PINs do not match')
      return
    }
    
    // If we have a current PIN field, validate it
    if (this.hasCurrentPinTarget && this.currentPinTarget.value.length !== 4) {
      this.showError('Please enter your current 4-digit PIN')
      return
    }
    
    // Submit the form via AJAX
    const formData = new FormData(this.formTarget)
    
    fetch('/api/user/update_pin', {
      method: 'POST',
      body: formData,
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      }
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        // Close the modal
        const modal = document.getElementById('pin-modal')
        modal.classList.add('hidden')
        modal.classList.remove('flex')
        
        // Show success message
        this.showSuccessMessage('PIN updated successfully')
      } else {
        this.showError(data.error || 'Failed to update PIN')
      }
    })
    .catch(error => {
      console.error('Error:', error)
      this.showError('An error occurred. Please try again.')
    })
  }
  
  showError(message) {
    if (this.hasErrorTarget) {
      this.errorTarget.textContent = message
      this.errorTarget.classList.remove('hidden')
    } else {
      alert(message)
    }
  }
  
  showSuccessMessage(message) {
    // Create a toast notification
    const toast = document.createElement('div')
    toast.className = 'fixed bottom-4 right-4 bg-green-500 text-white px-4 py-2 rounded-lg shadow-lg z-50 animate-fade-in-up'
    toast.textContent = message
    
    document.body.appendChild(toast)
    
    // Remove after 3 seconds
    setTimeout(() => {
      toast.classList.add('animate-fade-out-down')
      setTimeout(() => {
        document.body.removeChild(toast)
      }, 500)
    }, 3000)
  }
  
  // Helper methods for icons
  eyeIcon() {
    return '<svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" /><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" /></svg>'
  }
  
  eyeOffIcon() {
    return '<svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l3.59 3.59m0 0A9.953 9.953 0 0112 5c4.478 0 8.268 2.943 9.543 7a10.025 10.025 0 01-4.132 5.411m0 0L21 21" /></svg>'
  }
}
