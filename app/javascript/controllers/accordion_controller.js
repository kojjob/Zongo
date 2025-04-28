import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "icon"]

  connect() {
    // Initialize all accordions in closed state
    if (this.hasContentTarget) {
      this.contentTarget.classList.add("hidden");
      this.contentTarget.style.maxHeight = "0";
      
      // Initialize icon state
      if (this.hasIconTarget) {
        this.iconTarget.classList.remove("rotate-180");
      }
    }
  }

  toggle(event) {
    event.preventDefault();

    // Find the button that was clicked
    const button = event.currentTarget;

    // Find the content and icon associated with this button
    const contentIndex = this.contentTargets.findIndex(content =>
      content.previousElementSibling === button
    );

    if (contentIndex === -1) {
      // Try another approach - the content might be the next element sibling
      const content = button.nextElementSibling;
      const icon = button.querySelector('[data-accordion-target="icon"]');

      if (content && content.matches('[data-accordion-target="content"]')) {
        const isOpen = !content.classList.contains("hidden");

        if (isOpen) {
          this.closeItem(content, icon);
        } else {
          this.openItem(content, icon);
        }
      }
    } else {
      const content = this.contentTargets[contentIndex];
      const icon = this.iconTargets[contentIndex];

      const isOpen = !content.classList.contains("hidden");

      if (isOpen) {
        this.closeItem(content, icon);
      } else {
        this.openItem(content, icon);
      }
    }
  }

  openItem(content, icon) {
    // Show the content
    content.classList.remove("hidden");

    // Animate the height - use a small timeout to ensure the browser recognizes the display change
    setTimeout(() => {
      content.style.maxHeight = `${content.scrollHeight}px`;
    }, 10);

    // Rotate the icon if it exists
    if (icon) {
      icon.classList.add("rotate-180");
    }
  }

  closeItem(content, icon) {
    // Hide the content
    content.classList.add("hidden");
    content.style.maxHeight = "0";

    // Reset the icon if it exists
    if (icon) {
      icon.classList.remove("rotate-180");
    }
  }
}
