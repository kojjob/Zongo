import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="tab-navigation"
export default class extends Controller {
  static targets = ["tab", "panel"]

  connect() {
    console.log('Tab Navigation Controller connected')
    console.log('Found tab targets:', this.tabTargets.length)
    console.log('Found panel targets:', this.panelTargets.length)

    // Initialize the first tab as active if none is active
    if (!this.element.querySelector('.active-tab')) {
      if (this.tabTargets.length > 0) {
        console.log('Activating first tab')
        this.activateTab(this.tabTargets[0])
      }
    } else {
      // If there's already an active tab, make sure the corresponding panel is shown
      const activeTab = this.element.querySelector('.active-tab')
      if (activeTab) {
        this.activateTab(activeTab, false) // Don't update tab classes, just show the panel
      }
    }

    // Initialize card hover effects
    this.initializeCardEffects()
  }

  // Tab click handler
  switchTab(event) {
    event.preventDefault()
    console.log('Tab clicked:', event.currentTarget.dataset.target)
    this.activateTab(event.currentTarget, true)
  }

  // Activate the selected tab and show its panel
  activateTab(selectedTab, updateTabClasses = true) {
    if (!selectedTab) {
      console.log('No tab selected')
      return
    }

    const target = selectedTab.dataset.target
    console.log('Activating tab with target:', target)

    // Update active tab button if requested
    if (updateTabClasses) {
      this.tabTargets.forEach(tab => {
        tab.classList.remove('active-tab', 'border-primary-500', 'dark:border-primary-400', 'text-primary-600', 'dark:text-primary-400')
        tab.classList.add('border-transparent', 'text-gray-500', 'dark:text-gray-400')
      })

      selectedTab.classList.remove('border-transparent', 'text-gray-500', 'dark:text-gray-400')
      selectedTab.classList.add('active-tab', 'border-primary-500', 'dark:border-primary-400', 'text-primary-600', 'dark:text-primary-400')
    }

    // Show corresponding tab panel
    console.log('Looking for panel with data-id:', target)
    let foundPanel = false

    this.panelTargets.forEach(panel => {
      console.log('Panel data-id:', panel.dataset.id)
      if (panel.dataset.id === target) {
        console.log('Found matching panel, showing it')
        panel.classList.remove('hidden')
        foundPanel = true
      } else {
        panel.classList.add('hidden')
      }
    })

    if (!foundPanel) {
      console.log('No matching panel found for target:', target)
      // If no panel was found, show the first panel as a fallback
      if (this.panelTargets.length > 0) {
        this.panelTargets[0].classList.remove('hidden')
        console.log('Showing first panel as fallback')
      }
    }
  }

  // Initialize card hover effects
  initializeCardEffects() {
    const cards = document.querySelectorAll('.stat-card')
    cards.forEach(card => {
      const decoration = card.querySelector('.card-decoration')
      if (decoration) {
        card.addEventListener('mouseover', () => {
          decoration.style.opacity = '1'
        })

        card.addEventListener('mouseout', () => {
          decoration.style.opacity = '0'
        })
      }
    })
  }
}
