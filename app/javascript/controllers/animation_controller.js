import { Controller } from "@hotwired/stimulus"

/**
 * Animation Controller
 * 
 * This controller handles various animations throughout the application.
 * It provides functionality for:
 * - Scroll animations (reveal on scroll)
 * - Staggered animations
 * - Hover animations
 * - Parallax effects
 * - Counting animations
 */
export default class extends Controller {
  static targets = [
    "reveal",       // Elements that should be revealed on scroll
    "stagger",      // Container for staggered animations
    "staggerItem",  // Individual items for staggered animations
    "parallax",     // Elements with parallax effect
    "counter",      // Elements with counting animation
    "typewriter",   // Elements with typewriter effect
    "float"         // Elements with floating animation
  ]

  static values = {
    threshold: { type: Number, default: 0.1 },  // Intersection threshold for reveal
    delay: { type: Number, default: 100 },      // Delay between staggered items (ms)
    parallaxSpeed: { type: Number, default: 0.1 }, // Parallax effect speed
    countFrom: { type: Number, default: 0 },    // Start value for counter
    countTo: { type: Number, default: 100 },    // End value for counter
    countDuration: { type: Number, default: 2000 }, // Duration for counting animation (ms)
    typeSpeed: { type: Number, default: 50 }    // Speed for typewriter effect (ms)
  }

  connect() {
    // Initialize scroll animations if reveal targets exist
    if (this.hasRevealTarget) {
      this.initializeScrollAnimations()
    }

    // Initialize staggered animations if stagger target exists
    if (this.hasStaggerTarget && this.hasStaggerItemTargets) {
      this.initializeStaggeredAnimations()
    }

    // Initialize parallax effect if parallax targets exist
    if (this.hasParallaxTarget) {
      this.initializeParallax()
    }

    // Initialize counter animations if counter targets exist
    if (this.hasCounterTarget) {
      this.initializeCounters()
    }

    // Initialize typewriter effect if typewriter targets exist
    if (this.hasTypewriterTarget) {
      this.initializeTypewriter()
    }

    // Initialize float animations if float targets exist
    if (this.hasFloatTarget) {
      this.initializeFloat()
    }
  }

  disconnect() {
    // Clean up observers and event listeners
    if (this._observer) {
      this._observer.disconnect()
    }

    if (this._parallaxEnabled) {
      window.removeEventListener('scroll', this._handleParallax)
      window.removeEventListener('mousemove', this._handleMouseParallax)
    }
  }

  // Initialize scroll reveal animations using Intersection Observer
  initializeScrollAnimations() {
    const options = {
      root: null, // Use viewport as root
      rootMargin: '0px',
      threshold: this.thresholdValue
    }

    this._observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          entry.target.classList.add('is-visible')
          // Stop observing after animation is triggered
          this._observer.unobserve(entry.target)
        }
      })
    }, options)

    // Start observing all reveal targets
    this.revealTargets.forEach(element => {
      element.classList.add('reveal-on-scroll')
      this._observer.observe(element)
    })
  }

  // Initialize staggered animations
  initializeStaggeredAnimations() {
    this.staggerItemTargets.forEach((element, index) => {
      // Apply staggered delay based on index
      element.style.animationDelay = `${index * this.delayValue}ms`
    })
  }

  // Initialize parallax effect
  initializeParallax() {
    this._parallaxEnabled = true
    this._handleParallax = this.handleParallax.bind(this)
    this._handleMouseParallax = this.handleMouseParallax.bind(this)

    // Add event listeners for scroll and mouse movement
    window.addEventListener('scroll', this._handleParallax, { passive: true })
    window.addEventListener('mousemove', this._handleMouseParallax, { passive: true })

    // Initial calculation
    this.handleParallax()
  }

  // Handle parallax effect on scroll
  handleParallax() {
    const scrollPosition = window.pageYOffset
    
    this.parallaxTargets.forEach(element => {
      const speed = element.dataset.speed || this.parallaxSpeedValue
      const yPos = -(scrollPosition * speed)
      element.style.transform = `translateY(${yPos}px)`
    })
  }

  // Handle parallax effect on mouse movement
  handleMouseParallax(event) {
    const { clientX, clientY } = event
    const centerX = window.innerWidth / 2
    const centerY = window.innerHeight / 2
    
    const moveX = (clientX - centerX) / centerX
    const moveY = (clientY - centerY) / centerY
    
    this.parallaxTargets.forEach(element => {
      if (element.dataset.mouseParallax === 'true') {
        const speed = element.dataset.mouseSpeed || 15
        element.style.transform = `translate(${moveX * speed}px, ${moveY * speed}px)`
      }
    })
  }

  // Initialize counter animations
  initializeCounters() {
    this.counterTargets.forEach(element => {
      const countTo = parseInt(element.dataset.countTo || this.countToValue)
      const countFrom = parseInt(element.dataset.countFrom || this.countFromValue)
      const duration = parseInt(element.dataset.duration || this.countDurationValue)
      const formatter = element.dataset.formatter || 'none'
      
      this.animateCounter(element, countFrom, countTo, duration, formatter)
    })
  }

  // Animate counter from start to end value
  animateCounter(element, start, end, duration, formatter) {
    let startTimestamp = null
    const step = (timestamp) => {
      if (!startTimestamp) startTimestamp = timestamp
      const progress = Math.min((timestamp - startTimestamp) / duration, 1)
      const currentValue = Math.floor(progress * (end - start) + start)
      
      // Apply formatting if needed
      if (formatter === 'currency') {
        element.textContent = new Intl.NumberFormat('en-US', { 
          style: 'currency', 
          currency: 'USD' 
        }).format(currentValue)
      } else if (formatter === 'number') {
        element.textContent = new Intl.NumberFormat().format(currentValue)
      } else if (formatter === 'percentage') {
        element.textContent = `${currentValue}%`
      } else {
        element.textContent = currentValue
      }
      
      if (progress < 1) {
        window.requestAnimationFrame(step)
      }
    }
    
    window.requestAnimationFrame(step)
  }

  // Initialize typewriter effect
  initializeTypewriter() {
    this.typewriterTargets.forEach(element => {
      const text = element.dataset.text || element.textContent
      const speed = parseInt(element.dataset.speed || this.typeSpeedValue)
      
      // Clear the element and add typewriter class
      element.textContent = ''
      element.classList.add('typewriter-container')
      
      // Create a span for the cursor
      const cursor = document.createElement('span')
      cursor.classList.add('typewriter-cursor')
      cursor.textContent = '|'
      
      // Create a span for the text
      const textSpan = document.createElement('span')
      textSpan.classList.add('typewriter-text')
      
      // Append elements
      element.appendChild(textSpan)
      element.appendChild(cursor)
      
      // Start typewriter animation
      this.typeText(textSpan, text, 0, speed)
    })
  }

  // Type text character by character
  typeText(element, text, index, speed) {
    if (index < text.length) {
      element.textContent += text.charAt(index)
      index++
      setTimeout(() => this.typeText(element, text, index, speed), speed)
    }
  }

  // Initialize float animations
  initializeFloat() {
    this.floatTargets.forEach((element, index) => {
      // Apply random delay to create natural effect
      const randomDelay = Math.random() * 2
      element.style.animationDelay = `${randomDelay}s`
      
      // Apply random duration for more natural movement
      const baseDuration = 3
      const randomDuration = baseDuration + Math.random() * 2
      element.style.animationDuration = `${randomDuration}s`
      
      // Add float animation class
      element.classList.add('animate-float')
    })
  }

  // Manually trigger reveal animation (can be called from other controllers)
  reveal(event) {
    const element = event.currentTarget
    element.classList.add('is-visible')
  }

  // Manually trigger staggered animation
  triggerStagger(event) {
    const container = event.currentTarget
    const items = container.querySelectorAll('[data-animation-target="staggerItem"]')
    
    items.forEach((element, index) => {
      element.style.animationDelay = `${index * this.delayValue}ms`
      element.classList.add('animate-fade-in')
    })
  }

  // Manually trigger counter animation
  triggerCounter(event) {
    const element = event.currentTarget
    const countTo = parseInt(element.dataset.countTo || this.countToValue)
    const countFrom = parseInt(element.dataset.countFrom || this.countFromValue)
    const duration = parseInt(element.dataset.duration || this.countDurationValue)
    const formatter = element.dataset.formatter || 'none'
    
    this.animateCounter(element, countFrom, countTo, duration, formatter)
  }

  // Add hover animation classes
  addHoverAnimation(event) {
    const element = event.currentTarget
    const animationType = element.dataset.hoverAnimation || 'scale'
    
    if (animationType === 'scale') {
      element.classList.add('hover-scale-subtle')
    } else if (animationType === 'lift') {
      element.classList.add('hover-lift')
    } else if (animationType === 'glow') {
      element.classList.add('hover-glow')
    } else if (animationType === 'border') {
      element.classList.add('hover-border-highlight')
    }
  }

  // Remove hover animation classes
  removeHoverAnimation(event) {
    const element = event.currentTarget
    element.classList.remove(
      'hover-scale-subtle',
      'hover-lift',
      'hover-glow',
      'hover-border-highlight'
    )
  }
}
