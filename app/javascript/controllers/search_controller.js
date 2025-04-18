import { Controller } from "@hotwired/stimulus"

// Enhanced search controller with dropdown and filtering functionality
export default class extends Controller {
  static targets = ["input", "dropdown", "filters"]
  static values = {
    debounceMs: { type: Number, default: 300 }
  }

  connect() {
    console.log("Enhanced search controller connected")
    this.hideOptionsTimeout = null

    // Create a debounced version of the submit function
    this.debouncedSubmit = this.debounce(this.submit.bind(this), this.debounceMs)
    this.debouncedFilter = this.debounce(this.filterResults.bind(this), this.debounceMs)
  }

  // Debounce function to limit how often the search is performed
  debounce(func, wait) {
    let timeout
    return function() {
      const context = this
      const args = arguments
      clearTimeout(timeout)
      timeout = setTimeout(() => {
        func.apply(context, args)
      }, wait)
    }
  }

  // Called when input changes, debounces the submit
  debounceSubmit(event) {
    this.debouncedSubmit()
  }

  // Submits the form
  submit() {
    if (this.element.tagName === 'FORM') {
      this.element.requestSubmit()
    }
  }

  showOptions() {
    this.dropdownTarget.classList.remove('hidden')
    // Use setTimeout to allow the transition to work properly
    setTimeout(() => {
      this.dropdownTarget.classList.remove('opacity-0', 'scale-95', 'pointer-events-none')
      this.dropdownTarget.classList.add('opacity-100', 'scale-100')
    }, 10)
  }

  hideOptions() {
    this.dropdownTarget.classList.add('opacity-0', 'scale-95', 'pointer-events-none')
    // Wait for the transition to complete before hiding
    setTimeout(() => {
      this.dropdownTarget.classList.add('hidden')
    }, 200)
  }

  hideOptionsDelayed(event) {
    // Clear any existing timeout
    if (this.hideOptionsTimeout) {
      clearTimeout(this.hideOptionsTimeout)
    }

    // Set a new timeout to hide the options after a delay
    this.hideOptionsTimeout = setTimeout(() => {
      // Check if the related target is within the dropdown
      if (!this.dropdownTarget.contains(event.relatedTarget)) {
        this.hideOptions()
      }
    }, 200)
  }

  toggleOptions(event) {
    event.preventDefault()
    event.stopPropagation()

    if (this.dropdownTarget.classList.contains('hidden')) {
      this.showOptions()
      this.toggleFilters()
    } else {
      this.hideOptions()
    }
  }

  toggleFilters() {
    if (this.hasFiltersTarget) {
      if (this.filtersTarget.classList.contains('hidden')) {
        this.filtersTarget.classList.remove('hidden')
      } else {
        this.filtersTarget.classList.add('hidden')
      }
    }
  }

  filterResults() {
    // This would be implemented to filter search results in real-time
    console.log("Filtering results with:", this.inputTarget.value)

    // For demonstration purposes, we'll just log the search term
    // In a real implementation, this would filter the results shown in the dropdown
  }
}
