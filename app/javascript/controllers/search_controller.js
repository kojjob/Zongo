import { Controller } from "@hotwired/stimulus"

// Enhanced search controller with dropdown, filtering, and autocomplete functionality
export default class extends Controller {
  static targets = ["input", "dropdown", "filters", "suggestions", "form"]
  static values = {
    debounceMs: { type: Number, default: 300 },
    minLength: { type: Number, default: 2 }
  }

  connect() {
    console.log("Enhanced search controller connected")
    this.hideOptionsTimeout = null
    this.debounceTimer = null
    this.selectedIndex = -1
    this.suggestions = []

    // Create a debounced version of the submit function
    this.debouncedSubmit = this.debounce(this.submit.bind(this), this.debounceMs)
    this.debouncedFilter = this.debounce(this.filterResults.bind(this), this.debounceMs)

    // Close suggestions when clicking outside
    if (this.hasSuggestionsTarget) {
      document.addEventListener('click', this.handleClickOutside.bind(this))
    }
  }

  disconnect() {
    if (this.hasSuggestionsTarget) {
      document.removeEventListener('click', this.handleClickOutside.bind(this))
    }
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

  // Autocomplete methods
  handleInput() {
    const query = this.inputTarget.value.trim()

    // Clear previous timer
    clearTimeout(this.debounceTimer)

    // Hide suggestions if query is too short
    if (query.length < this.minLengthValue) {
      this.hideSuggestions()
      return
    }

    // Debounce the API call
    this.debounceTimer = setTimeout(() => {
      this.fetchSuggestions(query)
    }, 300)
  }

  fetchSuggestions(query) {
    fetch(`/search/autocomplete?q=${encodeURIComponent(query)}`)
      .then(response => response.json())
      .then(data => {
        this.renderSuggestions(data.suggestions, query)
      })
      .catch(error => {
        console.error('Error fetching search suggestions:', error)
      })
  }

  renderSuggestions(suggestions, query) {
    if (!this.hasSuggestionsTarget || suggestions.length === 0) {
      this.hideSuggestions()
      return
    }

    // Reset selected index
    this.selectedIndex = -1

    // Clear previous suggestions
    this.suggestionsTarget.innerHTML = ''

    // Create suggestion elements
    suggestions.forEach((suggestion, index) => {
      const item = document.createElement('li')
      item.className = 'px-4 py-2 hover:bg-gray-100 dark:hover:bg-gray-700 cursor-pointer'
      item.dataset.action = 'click->search#selectSuggestion'
      item.dataset.searchIndexParam = index

      // Highlight matching part of the suggestion
      const highlightedText = this.highlightMatch(suggestion, query)
      item.innerHTML = highlightedText

      this.suggestionsTarget.appendChild(item)
    })

    // Store suggestions for keyboard navigation
    this.suggestions = suggestions

    // Show suggestions
    this.showSuggestions()
  }

  highlightMatch(text, query) {
    const lowerText = text.toLowerCase()
    const lowerQuery = query.toLowerCase()
    const index = lowerText.indexOf(lowerQuery)

    if (index === -1) return text

    const before = text.substring(0, index)
    const match = text.substring(index, index + query.length)
    const after = text.substring(index + query.length)

    return `${before}<strong class="font-bold text-primary-600 dark:text-primary-400">${match}</strong>${after}`
  }

  showSuggestions() {
    if (this.hasSuggestionsTarget) {
      this.suggestionsTarget.classList.remove('hidden')
    }
  }

  hideSuggestions() {
    if (this.hasSuggestionsTarget) {
      this.suggestionsTarget.classList.add('hidden')
    }
  }

  handleKeydown(event) {
    // If suggestions are hidden or don't exist, do nothing
    if (!this.hasSuggestionsTarget || this.suggestionsTarget.classList.contains('hidden')) return

    const suggestionItems = this.suggestionsTarget.querySelectorAll('li')

    switch (event.key) {
      case 'ArrowDown':
        event.preventDefault()
        this.selectedIndex = Math.min(this.selectedIndex + 1, suggestionItems.length - 1)
        this.highlightSelected(suggestionItems)
        break

      case 'ArrowUp':
        event.preventDefault()
        this.selectedIndex = Math.max(this.selectedIndex - 1, -1)
        this.highlightSelected(suggestionItems)
        break

      case 'Enter':
        if (this.selectedIndex >= 0) {
          event.preventDefault()
          this.selectSuggestion({ currentTarget: suggestionItems[this.selectedIndex] })
        }
        break

      case 'Escape':
        event.preventDefault()
        this.hideSuggestions()
        break
    }
  }

  highlightSelected(items) {
    items.forEach((item, index) => {
      if (index === this.selectedIndex) {
        item.classList.add('bg-gray-100', 'dark:bg-gray-700')
      } else {
        item.classList.remove('bg-gray-100', 'dark:bg-gray-700')
      }
    })

    // Scroll into view if needed
    if (this.selectedIndex >= 0) {
      items[this.selectedIndex].scrollIntoView({ block: 'nearest' })
    }
  }

  selectSuggestion(event) {
    const index = event.currentTarget.dataset.searchIndexParam
    const suggestion = this.suggestions[index]

    this.inputTarget.value = suggestion
    this.hideSuggestions()

    // Submit the form if it exists
    if (this.hasFormTarget) {
      this.formTarget.requestSubmit()
    } else if (this.element.tagName === 'FORM') {
      this.element.requestSubmit()
    }
  }

  handleClickOutside(event) {
    if (this.hasSuggestionsTarget && !this.element.contains(event.target)) {
      this.hideSuggestions()
    }
  }
}
