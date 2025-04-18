import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  close(event) {
    event.preventDefault();
    this.element.classList.add("animate-fadeOut");
    
    setTimeout(() => {
      this.element.remove();
    }, 300);
  }
}