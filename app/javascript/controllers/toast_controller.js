import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["message"]
  
  connect() {
    // Make the toast template available to the controller
    this.template = document.getElementById('toast-template')
    
    // Register for custom toast events
    document.addEventListener('toast:show', this.showToast.bind(this))
  }
  
  disconnect() {
    document.removeEventListener('toast:show', this.showToast)
  }
  
  showToast(event) {
    const { type, message, duration } = event.detail
    
    // Create toast from template
    const toastNode = this.template.content.cloneNode(true).firstElementChild
    
    // Set toast content
    toastNode.querySelector('.toast-content').textContent = message
    
    // Set toast icon based on type
    const iconContainer = toastNode.querySelector('.toast-icon')
    
    switch (type) {
      case 'success':
        toastNode.classList.add('text-green-500', 'dark:text-green-400')
        iconContainer.parentElement.classList.add('bg-green-100', 'dark:bg-green-800')
        iconContainer.innerHTML = '<svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"></path></svg>'
        break
      case 'error':
        toastNode.classList.add('text-red-500', 'dark:text-red-400')
        iconContainer.parentElement.classList.add('bg-red-100', 'dark:bg-red-800')
        iconContainer.innerHTML = '<svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd"></path></svg>'
        break
      case 'warning':
        toastNode.classList.add('text-yellow-500', 'dark:text-yellow-400')
        iconContainer.parentElement.classList.add('bg-yellow-100', 'dark:bg-yellow-800')
        iconContainer.innerHTML = '<svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path fill-rule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clip-rule="evenodd"></path></svg>'
        break
      case 'info':
        toastNode.classList.add('text-blue-500', 'dark:text-blue-400')
        iconContainer.parentElement.classList.add('bg-blue-100', 'dark:bg-blue-800')
        iconContainer.innerHTML = '<svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clip-rule="evenodd"></path></svg>'
        break
      default:
        // Default is info
        toastNode.classList.add('text-blue-500', 'dark:text-blue-400')
        iconContainer.parentElement.classList.add('bg-blue-100', 'dark:bg-blue-800')
        iconContainer.innerHTML = '<svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clip-rule="evenodd"></path></svg>'
    }
    
    // Add to DOM
    this.element.appendChild(toastNode)
    
    // Schedule removal
    setTimeout(() => {
      this.closeToast({ target: toastNode.querySelector('[data-action="click->toast#closeToast"]') })
    }, duration || 5000)
  }
  
  closeToast(event) {
    const toastElement = event.target.closest('[data-toast-target="message"]')
    
    // Add exit animation
    toastElement.classList.add('opacity-0')
    
    // Remove after animation completes
    setTimeout(() => {
      if (toastElement.parentElement) {
        toastElement.remove()
      }
    }, 300)
  }
}