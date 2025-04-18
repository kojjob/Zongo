import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "header" ]
  static values = { offset: Number }

  connect() {
    // Initialize header state
    this.lastScrollTop = 0;
    this.toggleVisibility();
  }

  toggleVisibility() {
    if (!this.hasHeaderTarget) return;
    
    const st = window.pageYOffset || document.documentElement.scrollTop;
    
    if (st > this.offsetValue) {
      // Scrolled down past threshold - show header
      this.headerTarget.classList.remove("-translate-y-full");
      this.headerTarget.classList.add("translate-y-0");
    } else {
      // At top of page - hide header
      this.headerTarget.classList.remove("translate-y-0");
      this.headerTarget.classList.add("-translate-y-full");
    }
    
    this.lastScrollTop = st <= 0 ? 0 : st;
  }
}