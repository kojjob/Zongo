import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

// This controller handles sortable lists
export default class extends Controller {
  static values = {
    resourceUrl: String
  }

  connect() {
    this.sortable = Sortable.create(this.element, {
      handle: "[data-sortable-handle]",
      animation: 150,
      onEnd: this.onEnd.bind(this)
    })
  }

  disconnect() {
    if (this.sortable) {
      this.sortable.destroy()
    }
  }

  onEnd(event) {
    const itemIds = Array.from(this.element.querySelectorAll("[data-sortable-id]"))
      .map(item => item.dataset.sortableId)

    fetch(this.resourceUrlValue, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": this.getCSRFToken()
      },
      body: JSON.stringify({ banner_ids: itemIds })
    })
    .catch(error => {
      console.error("Error reordering items:", error)
    })
  }

  getCSRFToken() {
    return document.querySelector('meta[name="csrf-token"]').getAttribute('content')
  }
}
