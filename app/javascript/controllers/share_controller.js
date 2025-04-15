import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    url: String,
    title: String,
    description: { type: String, default: "" }
  }

  open(event) {
    event.preventDefault()
    
    // Check if Web Share API is available
    if (navigator.share) {
      navigator.share({
        title: this.titleValue,
        text: this.descriptionValue,
        url: this.urlValue
      })
      .catch(error => {
        console.error("Error sharing:", error)
        this.fallbackShare()
      })
    } else {
      this.fallbackShare()
    }
  }
  
  fallbackShare() {
    // Create a modal with sharing options
    const modalBackdrop = document.createElement('div')
    modalBackdrop.className = 'fixed inset-0 bg-black/50 z-40 flex items-center justify-center'
    
    const modal = document.createElement('div')
    modal.className = 'bg-white dark:bg-gray-800 rounded-xl p-6 shadow-xl max-w-sm w-full mx-4'
    
    // Modal header
    const header = document.createElement('div')
    header.className = 'flex justify-between items-center mb-4'
    
    const title = document.createElement('h3')
    title.className = 'text-xl font-bold text-gray-900 dark:text-white'
    title.textContent = 'Share Event'
    
    const closeButton = document.createElement('button')
    closeButton.className = 'text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200'
    closeButton.innerHTML = `
      <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
      </svg>
    `
    closeButton.addEventListener('click', () => {
      document.body.removeChild(modalBackdrop)
      document.body.style.overflow = ''
    })
    
    header.appendChild(title)
    header.appendChild(closeButton)
    
    // Modal body
    const body = document.createElement('div')
    body.className = 'space-y-4'
    
    // URL input
    const urlContainer = document.createElement('div')
    urlContainer.innerHTML = `
      <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Event URL</label>
      <div class="flex">
        <input type="text" value="${this.urlValue}" class="flex-1 px-3 py-2 border border-gray-300 dark:border-gray-700 rounded-l-md text-gray-900 dark:text-white bg-white dark:bg-gray-800" readonly>
        <button id="copy-url" class="px-3 py-2 bg-blue-600 text-white rounded-r-md hover:bg-blue-700 transition-colors">
          <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 5H6a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2v-1M8 5a2 2 0 002 2h2a2 2 0 002-2M8 5a2 2 0 012-2h2a2 2 0 012 2m0 0h2a2 2 0 012 2v3m2 4H10m0 0l3-3m-3 3l3 3"></path>
          </svg>
        </button>
      </div>
      <p id="copy-message" class="text-green-600 dark:text-green-400 text-sm mt-1 hidden">Copied to clipboard!</p>
    `
    
    // Social share buttons
    const socialButtons = document.createElement('div')
    socialButtons.className = 'grid grid-cols-3 gap-3 mt-4'
    socialButtons.innerHTML = `
      <a href="https://www.facebook.com/sharer/sharer.php?u=${encodeURIComponent(this.urlValue)}" target="_blank" class="flex flex-col items-center justify-center p-3 rounded-lg bg-blue-100 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400 hover:bg-blue-200 dark:hover:bg-blue-900/50 transition-colors">
        <svg class="h-6 w-6 mb-1" fill="currentColor" viewBox="0 0 24 24">
          <path d="M22 12c0-5.52-4.48-10-10-10S2 6.48 2 12c0 4.84 3.44 8.87 8 9.8V15H8v-3h2V9.5C10 7.57 11.57 6 13.5 6H16v3h-2c-.55 0-1 .45-1 1v2h3v3h-3v6.95c5.05-.5 9-4.76 9-9.95z"/>
        </svg>
        <span class="text-xs">Facebook</span>
      </a>
      
      <a href="https://twitter.com/intent/tweet?text=${encodeURIComponent(this.titleValue)}&url=${encodeURIComponent(this.urlValue)}" target="_blank" class="flex flex-col items-center justify-center p-3 rounded-lg bg-sky-100 dark:bg-sky-900/30 text-sky-600 dark:text-sky-400 hover:bg-sky-200 dark:hover:bg-sky-900/50 transition-colors">
        <svg class="h-6 w-6 mb-1" fill="currentColor" viewBox="0 0 24 24">
          <path d="M22.46 6c-.77.35-1.6.58-2.46.69.88-.53 1.56-1.37 1.88-2.38-.83.5-1.75.85-2.72 1.05C18.37 4.5 17.26 4 16 4c-2.35 0-4.27 1.92-4.27 4.29 0 .34.04.67.11.98C8.28 9.09 5.11 7.38 3 4.79c-.37.63-.58 1.37-.58 2.15 0 1.49.75 2.81 1.91 3.56-.71 0-1.37-.2-1.95-.5v.03c0 2.08 1.48 3.82 3.44 4.21a4.22 4.22 0 0 1-1.93.07 4.28 4.28 0 0 0 4 2.98 8.521 8.521 0 0 1-5.33 1.84c-.34 0-.68-.02-1.02-.06C3.44 20.29 5.7 21 8.12 21 16 21 20.33 14.46 20.33 8.79c0-.19 0-.37-.01-.56.84-.6 1.56-1.36 2.14-2.23z"/>
        </svg>
        <span class="text-xs">Twitter</span>
      </a>
      
      <a href="https://wa.me/?text=${encodeURIComponent(this.titleValue + " - " + this.urlValue)}" target="_blank" class="flex flex-col items-center justify-center p-3 rounded-lg bg-green-100 dark:bg-green-900/30 text-green-600 dark:text-green-400 hover:bg-green-200 dark:hover:bg-green-900/50 transition-colors">
        <svg class="h-6 w-6 mb-1" fill="currentColor" viewBox="0 0 24 24">
          <path d="M12.04 5.3c-4.97 0-9.01 4.04-9.01 9.01 0 1.64.44 3.23 1.28 4.62L2.92 22.5l3.63-1.33c1.32.72 2.81 1.1 4.34 1.1 4.97 0 9.01-4.04 9.01-9.01S17.01 5.3 12.04 5.3zm0 16.47c-1.47 0-2.91-.4-4.17-1.15l-.3-.18-3.1 1.13.94-3.05-.19-.31c-.78-1.25-1.19-2.69-1.19-4.16 0-4.13 3.36-7.49 7.49-7.49s7.49 3.36 7.49 7.49-3.36 7.49-7.49 7.49zm4.44-5.61c-.23-.11-1.37-.67-1.58-.75-.21-.08-.37-.12-.52.12-.15.23-.59.75-.73.9-.13.15-.27.17-.5.06-.67-.33-1.55-.65-2.32-1.54-.61-.61-1.02-1.36-1.14-1.59-.12-.23-.01-.35.09-.47.1-.1.21-.25.32-.38.1-.13.14-.21.21-.36.07-.14.04-.27-.02-.38-.06-.11-.52-1.26-.72-1.72-.19-.46-.38-.39-.52-.4-.14 0-.3-.03-.45-.03-.16 0-.39.06-.59.29-.2.23-.78.77-.78 1.87 0 1.1.8 2.17.91 2.32.12.15 1.67 2.54 4.04 3.56.24.11.42.18.57.24.8.34 1.52.29 2.1.17.64-.09 1.37-.56 1.57-1.11.2-.54.2-1.01.14-1.11-.06-.09-.22-.15-.44-.26z"/>
        </svg>
        <span class="text-xs">WhatsApp</span>
      </a>
    `
    
    // Put it all together
    body.appendChild(urlContainer)
    body.appendChild(socialButtons)
    
    // Assemble modal
    modal.appendChild(header)
    modal.appendChild(body)
    modalBackdrop.appendChild(modal)
    
    // Add to DOM
    document.body.appendChild(modalBackdrop)
    document.body.style.overflow = 'hidden' // Prevent scrolling
    
    // Add copy URL functionality
    const copyButton = modal.querySelector('#copy-url')
    const copyMessage = modal.querySelector('#copy-message')
    
    copyButton.addEventListener('click', () => {
      const urlInput = modal.querySelector('input')
      urlInput.select()
      document.execCommand('copy')
      
      copyMessage.classList.remove('hidden')
      setTimeout(() => {
        copyMessage.classList.add('hidden')
      }, 2000)
    })
    
    // Close when clicking outside
    modalBackdrop.addEventListener('click', (e) => {
      if (e.target === modalBackdrop) {
        document.body.removeChild(modalBackdrop)
        document.body.style.overflow = ''
      }
    })
    
    // Close on escape key
    document.addEventListener('keydown', function(e) {
      if (e.key === 'Escape' && document.body.contains(modalBackdrop)) {
        document.body.removeChild(modalBackdrop)
        document.body.style.overflow = ''
      }
    })
  }
}
