import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "form", 
    "submitButton", 
    "avatarPreview", 
    "avatarInput", 
    "removeAvatarButton",
    "saveIndicator"
  ]
  
  connect() {
    // Initialize any profile page functionality
    if (this.hasAvatarInputTarget) {
      this.avatarInputTarget.addEventListener('change', this.previewAvatar.bind(this))
    }
  }
  
  // Preview avatar before upload
  previewAvatar(event) {
    const file = event.target.files[0]
    if (!file) return
    
    if (this.hasAvatarPreviewTarget) {
      const reader = new FileReader()
      
      reader.onload = (e) => {
        this.avatarPreviewTarget.src = e.target.result
        this.avatarPreviewTarget.classList.remove('hidden')
        
        if (this.hasRemoveAvatarButtonTarget) {
          this.removeAvatarButtonTarget.classList.remove('hidden')
        }
      }
      
      reader.readAsDataURL(file)
    }
  }
  
  // Remove avatar preview
  removeAvatar(event) {
    event.preventDefault()
    
    if (this.hasAvatarInputTarget) {
      this.avatarInputTarget.value = ''
    }
    
    if (this.hasAvatarPreviewTarget) {
      this.avatarPreviewTarget.src = ''
      this.avatarPreviewTarget.classList.add('hidden')
    }
    
    if (this.hasRemoveAvatarButtonTarget) {
      this.removeAvatarButtonTarget.classList.add('hidden')
    }
  }
  
  // Submit form with loading state
  submitForm(event) {
    if (!this.hasFormTarget || !this.hasSubmitButtonTarget) return
    
    // Show loading state
    this.submitButtonTarget.disabled = true
    this.submitButtonTarget.classList.add('opacity-75', 'cursor-not-allowed')
    
    // Add spinner to button
    const originalButtonText = this.submitButtonTarget.innerHTML
    this.submitButtonTarget.innerHTML = `
      <div class="inline-block animate-spin w-4 h-4 mr-2 border-2 border-white border-t-transparent rounded-full"></div>
      Saving...
    `
    
    // Add loading bar at the top of the form
    const loadingBar = document.createElement('div')
    loadingBar.classList.add('loading-bar', 'absolute', 'top-0', 'left-0', 'right-0')
    this.formTarget.classList.add('relative')
    this.formTarget.prepend(loadingBar)
    
    // Submit the form
    this.formTarget.submit()
    
    // Show save indicator if available
    if (this.hasSaveIndicatorTarget) {
      this.saveIndicatorTarget.classList.remove('hidden')
      
      // Simulate progress
      let progress = 0
      const interval = setInterval(() => {
        progress += 5
        if (progress >= 100) {
          clearInterval(interval)
        }
        
        this.saveIndicatorTarget.style.width = `${progress}%`
      }, 100)
    }
    
    // Reset button after timeout (in case form submission fails)
    setTimeout(() => {
      this.submitButtonTarget.disabled = false
      this.submitButtonTarget.classList.remove('opacity-75', 'cursor-not-allowed')
      this.submitButtonTarget.innerHTML = originalButtonText
      
      if (loadingBar) {
        loadingBar.remove()
      }
      
      if (this.hasSaveIndicatorTarget) {
        this.saveIndicatorTarget.classList.add('hidden')
        this.saveIndicatorTarget.style.width = '0%'
      }
    }, 10000) // 10 second timeout
  }
  
  // Show loading state for any link
  showLinkLoading(event) {
    const link = event.currentTarget
    
    // Store original content
    const originalContent = link.innerHTML
    
    // Replace with loading spinner
    link.innerHTML = `
      <div class="inline-block animate-spin w-4 h-4 mr-2 border-2 border-current border-t-transparent rounded-full"></div>
      Loading...
    `
    
    // Disable the link temporarily
    link.classList.add('pointer-events-none', 'opacity-75')
    
    // Store original content for restoration after page load
    link.dataset.originalContent = originalContent
  }
}
