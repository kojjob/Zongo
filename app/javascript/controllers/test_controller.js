import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log("Test controller connected!")
    // Make a visible change to confirm it's working
    this.element.style.border = "3px solid green"
  }
}
