import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "mainImage", 
    "mainContainer", 
    "zoomLens", 
    "zoomResult", 
    "thumbnails", 
    "counter", 
    "lightbox", 
    "lightboxImage", 
    "lightboxCounter"
  ]
  
  connect() {
    this.currentIndex = 0
    this.totalImages = this.thumbnailsTarget ? this.thumbnailsTarget.children.length : 1
    this.zoomRatio = 2.5 // Zoom magnification level
    
    // Preload images for smoother experience
    if (this.hasMainImageTarget) {
      this.preloadImages()
    }
  }
  
  preloadImages() {
    if (this.hasThumbnailsTarget) {
      Array.from(this.thumbnailsTarget.children).forEach(thumbnail => {
        const img = new Image()
        img.src = thumbnail.dataset.src
      })
    }
  }
  
  // Image selection from thumbnails
  selectImage(event) {
    const button = event.currentTarget
    const index = parseInt(button.dataset.index)
    const src = button.dataset.src
    
    // Update main image
    this.mainImageTarget.src = src
    this.currentIndex = index
    
    // Update counter for mobile
    if (this.hasCounterTarget) {
      this.counterTarget.textContent = index + 1
    }
    
    // Update active thumbnail
    this.updateActiveThumbnail()
  }
  
  updateActiveThumbnail() {
    if (this.hasThumbnailsTarget) {
      Array.from(this.thumbnailsTarget.children).forEach((thumbnail, index) => {
        if (index === this.currentIndex) {
          thumbnail.classList.add('ring-2', 'ring-primary-500')
          thumbnail.classList.remove('hover:ring-2', 'hover:ring-primary-300')
        } else {
          thumbnail.classList.remove('ring-2', 'ring-primary-500')
          thumbnail.classList.add('hover:ring-2', 'hover:ring-primary-300')
        }
      })
    }
  }
  
  // Mobile navigation
  previousImage() {
    this.currentIndex = (this.currentIndex - 1 + this.totalImages) % this.totalImages
    this.updateGallery()
  }
  
  nextImage() {
    this.currentIndex = (this.currentIndex + 1) % this.totalImages
    this.updateGallery()
  }
  
  updateGallery() {
    if (this.hasThumbnailsTarget) {
      const thumbnail = this.thumbnailsTarget.children[this.currentIndex]
      const src = thumbnail.dataset.src
      
      // Update main image
      this.mainImageTarget.src = src
      
      // Update counter for mobile
      if (this.hasCounterTarget) {
        this.counterTarget.textContent = this.currentIndex + 1
      }
      
      // Update active thumbnail
      this.updateActiveThumbnail()
    }
  }
  
  // Image zoom functionality
  handleZoom(event) {
    if (!this.hasZoomLensTarget || !this.hasZoomResultTarget) return
    
    const { left, top, width, height } = this.mainContainerTarget.getBoundingClientRect()
    const x = event.clientX - left
    const y = event.clientY - top
    
    // Calculate lens position
    const lensWidth = this.zoomLensTarget.offsetWidth
    const lensHeight = this.zoomLensTarget.offsetHeight
    
    let lensX = x - lensWidth / 2
    let lensY = y - lensHeight / 2
    
    // Constrain lens to image boundaries
    lensX = Math.max(0, Math.min(width - lensWidth, lensX))
    lensY = Math.max(0, Math.min(height - lensHeight, lensY))
    
    // Position the lens
    this.zoomLensTarget.style.left = `${lensX}px`
    this.zoomLensTarget.style.top = `${lensY}px`
    
    // Calculate zoom result position
    const resultWidth = this.zoomResultTarget.offsetWidth
    const resultHeight = this.zoomResultTarget.offsetHeight
    
    const zoomX = lensX * this.zoomRatio
    const zoomY = lensY * this.zoomRatio
    
    // Position the zoomed image
    this.zoomResultTarget.style.backgroundImage = `url(${this.mainImageTarget.src})`
    this.zoomResultTarget.style.backgroundSize = `${width * this.zoomRatio}px ${height * this.zoomRatio}px`
    this.zoomResultTarget.style.backgroundPosition = `-${zoomX}px -${zoomY}px`
  }
  
  showZoomLens() {
    if (window.innerWidth < 768) return // Don't show zoom on mobile
    
    if (this.hasZoomLensTarget && this.hasZoomResultTarget) {
      this.zoomLensTarget.classList.remove('hidden')
      this.zoomResultTarget.classList.remove('hidden')
    }
  }
  
  hideZoomLens() {
    if (this.hasZoomLensTarget && this.hasZoomResultTarget) {
      this.zoomLensTarget.classList.add('hidden')
      this.zoomResultTarget.classList.add('hidden')
    }
  }
  
  // Lightbox functionality
  openLightbox() {
    if (this.hasLightboxTarget && this.hasLightboxImageTarget) {
      this.lightboxTarget.classList.remove('hidden')
      document.body.style.overflow = 'hidden' // Prevent scrolling
      
      // Update lightbox image
      this.lightboxImageTarget.src = this.mainImageTarget.src
      
      // Update lightbox counter
      if (this.hasLightboxCounterTarget) {
        this.lightboxCounterTarget.textContent = this.currentIndex + 1
      }
    }
  }
  
  closeLightbox() {
    if (this.hasLightboxTarget) {
      this.lightboxTarget.classList.add('hidden')
      document.body.style.overflow = '' // Restore scrolling
    }
  }
  
  // Lightbox navigation
  previousLightboxImage() {
    this.currentIndex = (this.currentIndex - 1 + this.totalImages) % this.totalImages
    this.updateLightbox()
  }
  
  nextLightboxImage() {
    this.currentIndex = (this.currentIndex + 1) % this.totalImages
    this.updateLightbox()
  }
  
  selectLightboxImage(event) {
    const button = event.currentTarget
    const index = parseInt(button.dataset.index)
    const src = button.dataset.src
    
    this.currentIndex = index
    this.updateLightbox()
  }
  
  updateLightbox() {
    if (this.hasThumbnailsTarget) {
      const thumbnail = this.thumbnailsTarget.children[this.currentIndex]
      const src = thumbnail.dataset.src
      
      // Update lightbox image
      this.lightboxImageTarget.src = src
      
      // Update lightbox counter
      if (this.hasLightboxCounterTarget) {
        this.lightboxCounterTarget.textContent = this.currentIndex + 1
      }
      
      // Update active thumbnail in lightbox
      const lightboxThumbnails = this.lightboxTarget.querySelectorAll('[data-action="click->product-gallery#selectLightboxImage"]')
      lightboxThumbnails.forEach((thumbnail, index) => {
        if (index === this.currentIndex) {
          thumbnail.classList.add('ring-2', 'ring-primary-500')
        } else {
          thumbnail.classList.remove('ring-2', 'ring-primary-500')
        }
      })
    }
  }
}
