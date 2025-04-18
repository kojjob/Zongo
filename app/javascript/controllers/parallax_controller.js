import { Controller } from "@hotwired/stimulus"

// Parallax effect controller for hero sections
export default class extends Controller {
  connect() {
    this.addParallaxEffect()
  }

  disconnect() {
    window.removeEventListener('mousemove', this.handleMouseMove)
  }

  addParallaxEffect() {
    this.handleMouseMove = this.handleMouseMove.bind(this)
    window.addEventListener('mousemove', this.handleMouseMove)
  }

  handleMouseMove(e) {
    const element = this.element
    const windowWidth = window.innerWidth
    const windowHeight = window.innerHeight
    
    // Calculate mouse position as a percentage of window size
    const mouseX = e.clientX / windowWidth
    const mouseY = e.clientY / windowHeight
    
    // Calculate the movement amount (smaller values for subtler effect)
    const moveX = (mouseX - 0.5) * 20 // 20px max movement
    const moveY = (mouseY - 0.5) * 20 // 20px max movement
    
    // Apply the transform with a slight delay for smoother effect
    requestAnimationFrame(() => {
      element.style.transform = `translate(${moveX}px, ${moveY}px) scale(1.05)`
    })
  }
}
