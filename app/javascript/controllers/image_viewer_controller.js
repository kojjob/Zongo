import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["backdrop", "image", "loader", "container", "counter", "prevButton", "nextButton"]
  
  connect() {
    this.scale = 1
    this.posX = 0
    this.posY = 0
    this.isDragging = false
    this.startX = 0
    this.startY = 0
    this.currentImages = []
    this.currentIndex = 0
  }
  
  open(event) {
    if (event && event.currentTarget && event.currentTarget.src) {
      this.loadImage(event.currentTarget.src, event.currentTarget.alt || "Image")
    }
    
    // Find all nearby images that might be part of a gallery
    if (event && event.currentTarget) {
      this.findGalleryImages(event.currentTarget)
    }
    
    this.element.classList.remove("hidden")
    
    // Enable scroll lock
    document.body.style.overflow = "hidden"
    
    // Trigger animations with a slight delay for proper rendering
    setTimeout(() => {
      this.backdropTarget.classList.remove("opacity-0")
    }, 10)
  }
  
  close(event) {
    if (event) event.preventDefault()
    
    this.backdropTarget.classList.add("opacity-0")
    this.imageTarget.classList.add("opacity-0")
    
    // Hide after animation completes
    setTimeout(() => {
      this.element.classList.add("hidden")
      
      // Reset state
      this.resetView()
      
      // Disable scroll lock
      document.body.style.overflow = ""
    }, 300)
  }
  
  handleKeydown(event) {
    if (event.key === "Escape") {
      this.close(event)
    } else if (event.key === "ArrowLeft") {
      this.prev(event)
    } else if (event.key === "ArrowRight") {
      this.next(event)
    } else if (event.key === "+" || event.key === "=") {
      this.zoomIn(event)
    } else if (event.key === "-") {
      this.zoomOut(event)
    } else if (event.key === "0") {
      this.resetZoom(event)
    }
  }
  
  handleBackdropClick(event) {
    // Only close if clicking directly on the backdrop, not the image
    if (event.target === this.backdropTarget || event.target === this.containerTarget) {
      this.close(event)
    }
  }
  
  handleWheel(event) {
    if (event.ctrlKey || event.metaKey) {
      event.preventDefault()
      if (event.deltaY < 0) {
        this.zoomIn(event)
      } else {
        this.zoomOut(event)
      }
    }
  }
  
  zoomIn(event) {
    if (event) event.preventDefault()
    this.scale = Math.min(this.scale + 0.25, 5)
    this.applyTransform()
  }
  
  zoomOut(event) {
    if (event) event.preventDefault()
    this.scale = Math.max(this.scale - 0.25, 0.5)
    this.applyTransform()
  }
  
  resetZoom(event) {
    if (event) event.preventDefault()
    this.scale = 1
    this.posX = 0
    this.posY = 0
    this.applyTransform()
  }
  
  startDrag(event) {
    // Only initiate drag if image is zoomed in
    if (this.scale <= 1) return
    
    this.isDragging = true
    
    if (event.type === "mousedown") {
      this.startX = event.clientX
      this.startY = event.clientY
    } else if (event.type === "touchstart") {
      this.startX = event.touches[0].clientX
      this.startY = event.touches[0].clientY
    }
  }
  
  drag(event) {
    if (!this.isDragging) return
    
    event.preventDefault()
    
    let clientX, clientY
    if (event.type === "mousemove") {
      clientX = event.clientX
      clientY = event.clientY
    } else if (event.type === "touchmove") {
      clientX = event.touches[0].clientX
      clientY = event.touches[0].clientY
    }
    
    const deltaX = clientX - this.startX
    const deltaY = clientY - this.startY
    
    this.posX += deltaX
    this.posY += deltaY
    
    this.startX = clientX
    this.startY = clientY
    
    this.applyTransform()
  }
  
  endDrag() {
    this.isDragging = false
  }
  
  applyTransform() {
    this.containerTarget.style.transform = `translate(${this.posX}px, ${this.posY}px) scale(${this.scale})`
  }
  
  resetView() {
    this.scale = 1
    this.posX = 0
    this.posY = 0
    this.applyTransform()
    this.imageTarget.classList.add("opacity-0")
  }
  
  loadImage(src, alt = "Image") {
    // Show loader
    this.loaderTarget.classList.remove("hidden")
    this.imageTarget.classList.add("opacity-0")
    
    // Reset transform
    this.resetView()
    
    // Load the new image
    this.imageTarget.src = src
    this.imageTarget.alt = alt
    
    this.imageTarget.onload = () => {
      // Hide loader and show image
      this.loaderTarget.classList.add("hidden")
      this.imageTarget.classList.remove("opacity-0")
    }
    
    this.imageTarget.onerror = () => {
      // Handle error
      this.loaderTarget.classList.add("hidden")
      alert("Failed to load image")
    }
  }
  
  findGalleryImages(currentImage) {
    // Find all images in the same container/gallery
    const gallery = currentImage.closest(".gallery") // Adjust selector based on your HTML structure
    
    if (gallery) {
      this.currentImages = Array.from(gallery.querySelectorAll("img"))
    } else {
      // If no gallery container is found, find images that might be siblings or nearby
      const allImages = Array.from(document.querySelectorAll("img[src]"))
      
      // Filter out tiny images, icons, etc.
      this.currentImages = allImages.filter(img => {
        return img.naturalWidth > 100 && img.naturalHeight > 100
      })
    }
    
    // Find the index of the current image
    this.currentIndex = this.currentImages.findIndex(img => img === currentImage)
    
    // Update counter
    this.updateCounter()
    
    // Show/hide navigation buttons based on gallery size
    if (this.currentImages.length <= 1) {
      this.prevButtonTarget.classList.add("hidden")
      this.nextButtonTarget.classList.add("hidden")
    } else {
      this.prevButtonTarget.classList.remove("hidden")
      this.nextButtonTarget.classList.remove("hidden")
    }
  }
  
  prev(event) {
    if (event) event.preventDefault()
    if (this.currentImages.length <= 1) return
    
    this.currentIndex = (this.currentIndex - 1 + this.currentImages.length) % this.currentImages.length
    const img = this.currentImages[this.currentIndex]
    
    this.loadImage(img.src, img.alt)
    this.updateCounter()
  }
  
  next(event) {
    if (event) event.preventDefault()
    if (this.currentImages.length <= 1) return
    
    this.currentIndex = (this.currentIndex + 1) % this.currentImages.length
    const img = this.currentImages[this.currentIndex]
    
    this.loadImage(img.src, img.alt)
    this.updateCounter()
  }
  
  updateCounter() {
    if (this.hasCounterTarget && this.currentImages.length > 0) {
      this.counterTarget.textContent = `Image ${this.currentIndex + 1} of ${this.currentImages.length}`
    }
  }
}