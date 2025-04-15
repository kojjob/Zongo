import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="share-modal"
export default class extends Controller {
  static targets = ["modal", "urlInput", "copyMessage", "facebookLink", "twitterLink", "whatsappLink", "emailLink"]
  static values = { title: String, url: String, description: String }
  
  connect() {
    // Set up social links when controller connects
    this.updateSocialLinks()
    
    // Add event listener to close on escape key
    document.addEventListener('keydown', this.handleKeyDown)
    
    // Add event listener to close when clicking outside modal
    this.modalTarget.addEventListener('click', this.handleOutsideClick)
  }
  
  disconnect() {
    // Clean up event listeners
    document.removeEventListener('keydown', this.handleKeyDown)
    this.modalTarget.removeEventListener('click', this.handleOutsideClick)
  }
  
  open() {
    this.modalTarget.classList.remove('hidden')
    document.body.style.overflow = 'hidden' // Prevent scrolling while modal is open
    this.updateSocialLinks()
  }
  
  close() {
    this.modalTarget.classList.add('hidden')
    document.body.style.overflow = '' // Restore scrolling
    
    // Hide the copy message if it was shown
    if (!this.copyMessageTarget.classList.contains('hidden')) {
      this.copyMessageTarget.classList.add('hidden')
    }
  }
  
  copyUrl() {
    // Select the URL input
    this.urlInputTarget.select()
    this.urlInputTarget.setSelectionRange(0, 99999) // For mobile devices
    
    // Copy to clipboard
    try {
      navigator.clipboard.writeText(this.urlInputTarget.value)
      this.showCopyMessage()
    } catch (err) {
      // Fallback for older browsers
      document.execCommand('copy')
      this.showCopyMessage()
    }
  }
  
  showCopyMessage() {
    // Show the copy message
    this.copyMessageTarget.classList.remove('hidden')
    
    // Hide the message after 2 seconds
    setTimeout(() => {
      this.copyMessageTarget.classList.add('hidden')
    }, 2000)
  }
  
  updateSocialLinks() {
    const encodedUrl = encodeURIComponent(this.urlValue)
    const encodedTitle = encodeURIComponent(this.titleValue)
    const encodedDescription = encodeURIComponent(decodeURIComponent(this.descriptionValue)) // First decode from the data attribute
    
    // Update Facebook share link
    this.facebookLinkTarget.href = `https://www.facebook.com/sharer/sharer.php?u=${encodedUrl}`
    
    // Update Twitter share link
    this.twitterLinkTarget.href = `https://twitter.com/intent/tweet?text=${encodedTitle}&url=${encodedUrl}`
    
    // Update WhatsApp share link
    this.whatsappLinkTarget.href = `https://wa.me/?text=${encodedTitle} - ${encodedUrl}`
    
    // Update Email share link
    this.emailLinkTarget.href = `mailto:?subject=${encodedTitle}&body=${encodedDescription}%0A%0A${encodedUrl}`
  }
  
  handleKeyDown = (event) => {
    if (event.key === 'Escape' && !this.modalTarget.classList.contains('hidden')) {
      this.close()
    }
  }
  
  handleOutsideClick = (event) => {
    // Close if the click is directly on the modal background (not its children)
    if (event.target === this.modalTarget) {
      this.close()
    }
  }
}
