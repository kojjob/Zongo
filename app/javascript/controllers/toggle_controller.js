import { Controller } from "@hotwired/stimulus"

// Simple toggle controller that just toggles the checkbox
export default class extends Controller {
  static targets = ["checkbox"]

  connect() {
    console.log("Toggle controller connected")
  }

  toggle() {
    if (this.hasCheckboxTarget) {
      this.checkboxTarget.checked = !this.checkboxTarget.checked
    }
  }
}
