import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="modal"
export default class extends Controller {
  static targets = ["container"]

  connect() {
    // Add event listener for ESC key
    document.addEventListener('keydown', this.handleKeyDown.bind(this))

    // Only prevent body scrolling if the modal is visible
    if (!this.element.classList.contains('hidden')) {
      document.body.classList.add('overflow-hidden')
    }

    // Add animation classes
    this.element.classList.add('transition-opacity', 'duration-300')
    if (this.hasContainerTarget) {
      this.containerTarget.classList.add('transition-transform', 'duration-300')
    }
  }

  disconnect() {
    // Remove event listener when controller is disconnected
    document.removeEventListener('keydown', this.handleKeyDown.bind(this))

    // Re-enable body scrolling
    document.body.classList.remove('overflow-hidden')
  }

  handleKeyDown(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }

  open(event) {
    if (event) {
      event.preventDefault()
    }

    let modal;

    // Check if we're opening from a button or directly
    if (event && event.currentTarget.dataset.modalTarget) {
      // Get the modal ID from the data attribute
      const modalId = event.currentTarget.dataset.modalTarget
      modal = document.getElementById(modalId)
    } else {
      // We're calling open() directly on the modal
      modal = this.element
    }

    if (modal) {
      // Show the modal with animation
      modal.classList.remove('hidden')
      modal.classList.add('flex')

      // Animate in
      requestAnimationFrame(() => {
        requestAnimationFrame(() => {
          modal.classList.add('opacity-100')
          modal.classList.remove('opacity-0')

          const container = modal.querySelector('[data-modal-target="container"]')
          if (container) {
            container.classList.add('translate-y-0', 'opacity-100')
            container.classList.remove('-translate-y-4', 'opacity-0')
          }
        })
      })

      // Prevent body scrolling
      document.body.classList.add('overflow-hidden')

      // Focus the first input if available
      setTimeout(() => {
        const firstInput = modal.querySelector('input, button:not([data-action="modal#close"]), select, textarea')
        if (firstInput) {
          firstInput.focus()
        }
      }, 300)
    }
  }

  close(event) {
    if (event) {
      event.preventDefault()
    }

    // Get the modal element (the element with the controller)
    const modal = this.element

    // Animate out
    requestAnimationFrame(() => {
      modal.classList.remove('opacity-100')
      modal.classList.add('opacity-0')

      if (this.hasContainerTarget) {
        this.containerTarget.classList.remove('translate-y-0', 'opacity-100')
        this.containerTarget.classList.add('-translate-y-4', 'opacity-0')
      }

      // Hide the modal after animation completes
      setTimeout(() => {
        modal.classList.add('hidden')
        modal.classList.remove('flex')

        // Re-enable body scrolling
        document.body.classList.remove('overflow-hidden')

        // Reset form if present
        const form = modal.querySelector('form')
        if (form) {
          form.reset()
        }

        // Clear any error messages
        const errorElements = modal.querySelectorAll('.error-message')
        errorElements.forEach(el => {
          el.textContent = ''
          el.classList.add('hidden')
        })
      }, 300)
    })
  }
}
