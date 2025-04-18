import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "control", "content", "icon" ]

  connect() {
    // Initialize the accordion in closed state
    this.close();
  }

  toggle(event) {
    event.preventDefault();

    if (!this.hasContentTarget) return;

    // Check if the accordion is currently open
    const isOpen = !this.contentTarget.classList.contains("hidden");

    if (isOpen) {
      this.close();
    } else {
      this.open();
    }
  }

  open() {
    if (!this.hasContentTarget) return;

    // Show the content
    this.contentTarget.classList.remove("hidden");

    // Rotate the icon if it exists
    if (this.hasIconTarget) {
      this.iconTarget.classList.add("rotate-180");
    }

    // Animate the height
    setTimeout(() => {
      this.contentTarget.style.maxHeight = this.contentTarget.scrollHeight + "px";
    }, 10);
  }

  close() {
    if (!this.hasContentTarget) return;

    // Hide the content
    this.contentTarget.classList.add("hidden");
    this.contentTarget.style.maxHeight = "0";

    // Reset the icon if it exists
    if (this.hasIconTarget) {
      this.iconTarget.classList.remove("rotate-180");
    }
  }
}
