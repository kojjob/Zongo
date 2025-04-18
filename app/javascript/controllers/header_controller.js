import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "wrapper" ]

  connect() {
    // Add animation classes once connected
    if (this.hasWrapperTarget) {
      this.wrapperTarget.classList.add("animate-fadeIn");
    }
  }
}