import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "header" ]

  connect() {
    // Initialize header state
    this.lastScrollTop = 0;
    
    // Default offset value
    this.offsetValue = 150;
    
    // Make the header visible on connect
    if (this.hasHeaderTarget) {
      this.headerTarget.classList.add("opacity-100");
    }
  }

  onScroll() {
    if (!this.hasHeaderTarget) return;
    
    const st = window.pageYOffset || document.documentElement.scrollTop;
    
    if (st > this.offsetValue) {
      // Scrolled down past threshold - show header
      this.headerTarget.classList.remove("-translate-y-full");
      this.headerTarget.classList.add("translate-y-0");
      this.headerTarget.classList.add("visible");
      this.headerTarget.classList.add("opacity-100");
    } else {
      // At top of page - hide header
      this.headerTarget.classList.remove("translate-y-0");
      this.headerTarget.classList.add("-translate-y-full");
      this.headerTarget.classList.remove("visible");
    }
    
    this.lastScrollTop = st <= 0 ? 0 : st;
  }
}