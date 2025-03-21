import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview"]
  
  connect() {
    if (this.hasInputTarget) {
      this.inputTarget.addEventListener("change", this.previewAvatar.bind(this))
    }
  }
  
  previewAvatar(event) {
    const input = event.target
    
    if (input.files && input.files[0]) {
      const reader = new FileReader()
      
      reader.onload = (e) => {
        if (this.hasPreviewTarget) {
          this.previewTarget.src = e.target.result
          this.previewTarget.classList.remove("hidden")
          
          // Hide the initials placeholder if it exists
          const initialsPlaceholder = this.element.querySelector(".initials-placeholder")
          if (initialsPlaceholder) {
            initialsPlaceholder.classList.add("hidden")
          }
          
          // Make sure we also render the preview in any other avatar displays
          const avatarImgs = document.querySelectorAll('.user-avatar-display')
          if (avatarImgs) {
            avatarImgs.forEach(img => {
              img.src = e.target.result
              // Find parent element with initials placeholder
              const parent = img.closest('.avatar-container')
              if (parent) {
                const initialsEl = parent.querySelector('.initials-placeholder')
                if (initialsEl) {
                  initialsEl.classList.add('hidden')
                }
              }
              img.classList.remove('hidden')
            })
          }
        }
      }
      
      reader.readAsDataURL(input.files[0])
    }
  }
}