import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["reveal", "progress", "scrollTop"]
  
  connect() {
    this.setupScrollAnimation()
    
    if (this.hasProgressTarget) {
      this.setupScrollProgress()
    }
    
    if (this.hasScrollTopTarget) {
      this.setupScrollToTop()
    }
  }
  
  setupScrollAnimation() {
    // Intersection Observer for reveal-on-scroll elements
    if (this.hasRevealTarget) {
      const observer = new IntersectionObserver(
        (entries) => {
          entries.forEach(entry => {
            if (entry.isIntersecting) {
              entry.target.classList.add('is-visible')
              // Unobserve after animation to improve performance
              observer.unobserve(entry.target)
            }
          })
        },
        { 
          root: null,
          threshold: 0.1,
          rootMargin: '0px 0px -100px 0px'
        }
      )
      
      this.revealTargets.forEach(el => observer.observe(el))
    }
  }
  
  setupScrollProgress() {
    window.addEventListener('scroll', () => {
      const winScroll = document.body.scrollTop || document.documentElement.scrollTop
      const height = document.documentElement.scrollHeight - document.documentElement.clientHeight
      const scrolled = (winScroll / height) * 100
      
      this.progressTarget.style.width = scrolled + "%"
    })
  }
  
  setupScrollToTop() {
    window.addEventListener('scroll', () => {
      if (window.pageYOffset > 300) {
        this.scrollTopTarget.classList.add('visible')
      } else {
        this.scrollTopTarget.classList.remove('visible')
      }
    })
    
    this.scrollTopTarget.addEventListener('click', () => {
      window.scrollTo({
        top: 0,
        behavior: 'smooth'
      })
    })
  }
  
  // Additional animation methods can be added here
}