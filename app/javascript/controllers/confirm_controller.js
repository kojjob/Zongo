import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    title: String,
    body: String,
    confirm: { type: String, default: "Confirm" },
    cancel: { type: String, default: "Cancel" },
    url: String,
    method: { type: String, default: "post" }
  }

  connect() {
    // Initialize modal, but don't show it yet
  }

  show(event) {
    event.preventDefault()
    
    // Create modal backdrop
    this.backdrop = document.createElement('div')
    this.backdrop.className = 'fixed inset-0 bg-black/50 z-40 flex items-center justify-center'
    
    // Create modal content
    const modal = document.createElement('div')
    modal.className = 'bg-white dark:bg-gray-800 rounded-xl shadow-xl p-6 max-w-md w-full mx-4'
    
    // Modal header
    const header = document.createElement('div')
    header.className = 'flex justify-between items-center mb-4'
    
    const title = document.createElement('h3')
    title.className = 'text-xl font-bold text-gray-900 dark:text-white'
    title.textContent = this.titleValue
    
    const closeButton = document.createElement('button')
    closeButton.className = 'text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200'
    closeButton.innerHTML = `
      <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
      </svg>
    `
    closeButton.addEventListener('click', this.cancel.bind(this))
    
    header.appendChild(title)
    header.appendChild(closeButton)
    
    // Modal body
    const body = document.createElement('div')
    body.className = 'mb-6 text-gray-700 dark:text-gray-300'
    body.textContent = this.bodyValue
    
    // Modal footer with buttons
    const footer = document.createElement('div')
    footer.className = 'flex justify-end space-x-3'
    
    const cancelButton = document.createElement('button')
    cancelButton.className = 'px-4 py-2 border border-gray-300 dark:border-gray-700 text-gray-700 dark:text-gray-300 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700'
    cancelButton.textContent = this.cancelValue
    cancelButton.addEventListener('click', this.cancel.bind(this))
    
    const confirmButton = document.createElement('button')
    confirmButton.className = 'px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700'
    confirmButton.textContent = this.confirmValue
    confirmButton.addEventListener('click', this.confirm.bind(this))
    
    footer.appendChild(cancelButton)
    footer.appendChild(confirmButton)
    
    // Assemble modal
    modal.appendChild(header)
    modal.appendChild(body)
    modal.appendChild(footer)
    
    this.backdrop.appendChild(modal)
    document.body.appendChild(this.backdrop)
    
    // Prevent scrolling while modal is open
    document.body.style.overflow = 'hidden'
    
    // Set up escape key handler
    this.escapeHandler = (e) => {
      if (e.key === 'Escape') this.cancel()
    }
    document.addEventListener('keydown', this.escapeHandler)
    
    // Set up click outside handler
    this.backdrop.addEventListener('click', (e) => {
      if (e.target === this.backdrop) this.cancel()
    })
  }
  
  confirm() {
    // Create and submit form programmatically
    const form = document.createElement('form')
    form.method = 'post'
    form.action = this.urlValue
    
    // Add CSRF token
    const csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content')
    const csrfInput = document.createElement('input')
    csrfInput.type = 'hidden'
    csrfInput.name = 'authenticity_token'
    csrfInput.value = csrfToken
    
    // Add method override if needed
    if (this.methodValue !== 'post') {
      const methodInput = document.createElement('input')
      methodInput.type = 'hidden'
      methodInput.name = '_method'
      methodInput.value = this.methodValue
      form.appendChild(methodInput)
    }
    
    form.appendChild(csrfInput)
    document.body.appendChild(form)
    form.submit()
  }
  
  cancel() {
    // Remove modal and clean up
    document.body.removeChild(this.backdrop)
    document.body.style.overflow = ''
    document.removeEventListener('keydown', this.escapeHandler)
  }
}
