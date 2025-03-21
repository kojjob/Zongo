import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="accordion"
export default class extends Controller {
  static targets = ["item", "content", "icon"]
  
  connect() {
    console.log("Accordion controller connected")
  }
  
  toggle(event) {
    const content = event.currentTarget.nextElementSibling
    const icon = event.currentTarget.querySelector('svg')
    
    if (content.classList.contains('hidden')) {
      content.classList.remove('hidden')
      icon.classList.add('rotate-180')
    } else {
      content.classList.add('hidden')
      icon.classList.remove('rotate-180')
    }
  }
}
