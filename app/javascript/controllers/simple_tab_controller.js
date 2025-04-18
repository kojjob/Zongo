import { Controller } from "@hotwired/stimulus"

// A simplified tab controller that uses vanilla JavaScript for maximum reliability
export default class extends Controller {
  static targets = ["tab", "panel"]
  
  connect() {
    console.log("SimpleTabController connected")
    console.log("Tabs:", this.tabTargets.length)
    console.log("Panels:", this.panelTargets.length)
    
    // Ensure we have the same number of tabs and panels
    if (this.tabTargets.length !== this.panelTargets.length) {
      console.warn(`Mismatch between tabs (${this.tabTargets.length}) and panels (${this.panelTargets.length})`)
    }
    
    // Initialize by showing the active tab or the first tab
    const activeTabIndex = this.tabTargets.findIndex(tab => tab.classList.contains('active-tab'))
    if (activeTabIndex >= 0) {
      this.showTab(activeTabIndex)
    } else if (this.tabTargets.length > 0) {
      this.showTab(0)
    }
  }
  
  // Called when a tab is clicked
  select(event) {
    event.preventDefault()
    const clickedTab = event.currentTarget
    const tabIndex = this.tabTargets.indexOf(clickedTab)
    if (tabIndex !== -1) {
      this.showTab(tabIndex)
    }
  }
  
  // Show the tab at the given index and hide all others
  showTab(index) {
    console.log(`Showing tab at index ${index}`)
    
    // Update tab states
    this.tabTargets.forEach((tab, i) => {
      if (i === index) {
        tab.classList.add('active-tab', 'border-primary-500', 'dark:border-primary-400', 'text-primary-600', 'dark:text-primary-400')
        tab.classList.remove('border-transparent', 'text-gray-500', 'dark:text-gray-400')
      } else {
        tab.classList.remove('active-tab', 'border-primary-500', 'dark:border-primary-400', 'text-primary-600', 'dark:text-primary-400')
        tab.classList.add('border-transparent', 'text-gray-500', 'dark:text-gray-400')
      }
    })
    
    // Update panel visibility
    this.panelTargets.forEach((panel, i) => {
      if (i === index) {
        panel.classList.remove('hidden')
      } else {
        panel.classList.add('hidden')
      }
    })
  }
}
