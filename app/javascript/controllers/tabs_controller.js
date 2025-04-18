import { Controller } from "@hotwired/stimulus"

/**
 * Universal Tab Controller
 * 
 * A flexible and comprehensive tab controller for the Ghana Super App
 * that supports multiple tab implementations and styles.
 * 
 * Features:
 * - Automatic initialization of active tab (by data attribute, URL hash, or first tab)
 * - ARIA support for accessibility
 * - URL hash synchronization (optional)
 * - Persistence via localStorage (optional)
 * - Animation support for tab transitions
 * - Tab scroll support for many tabs
 * - Works with dynamic content (Turbo)
 * - Various tab styles (bordered, pills, minimal, etc.)
 * 
 * CSS classes handled automatically:
 * - Active state
 * - Hover state
 * - Focus state
 * - Disabled state
 */
export default class extends Controller {
  static targets = ["tab", "panel", "tabsList", "panelsContainer"]
  
  static values = {
    // Namespace to use for localStorage persistence (if enabled)
    storageKey: { type: String, default: 'superghanaTabs' },
    
    // Whether to update the URL hash when changing tabs
    syncHash: { type: Boolean, default: false },
    
    // Whether to persist active tab between page loads
    persist: { type: Boolean, default: false },
    
    // Default active tab index or ID
    defaultTab: { type: String, default: '0' },
    
    // The currently active tab (can be index or ID)
    activeTab: { type: String, default: null },
    
    // Whether to use smooth animations between tab transitions
    animate: { type: Boolean, default: true },
    
    // Visual style (bordered, pills, minimal, underline)
    style: { type: String, default: 'underline' },
    
    // Orientation (horizontal, vertical)
    orientation: { type: String, default: 'horizontal' },
    
    // Scroll tabs that overflow (for many tabs)
    scrollable: { type: Boolean, default: true },
    
    // Whether to use a data-id or index-based tab identification
    useIds: { type: Boolean, default: true },
    
    // Use debug mode
    debug: { type: Boolean, default: false }
  }
  
  /**
   * Initialize the controller when connected
   */
  connect() {
    if (this.debugValue) {
      console.log("Universal Tab Controller connected", {
        tabs: this.tabTargets.length,
        panels: this.panelTargets.length,
        activeTab: this.activeTabValue,
        style: this.styleValue
      })
    }
    
    // Set up ARIA roles and relationships
    this.setupAccessibility()
    
    // Initialize the tab setup based on various criteria
    this.initializeTabs()
    
    // Set up listeners for hash changes if syncing with hash
    if (this.syncHashValue) {
      window.addEventListener('hashchange', this.handleHashChange.bind(this))
    }
    
    // Set up tab scrolling if enabled
    if (this.scrollableValue && this.hasTabsListTarget) {
      this.setupTabScrolling()
    }
  }
  
  /**
   * Clean up event listeners when disconnected
   */
  disconnect() {
    if (this.syncHashValue) {
      window.removeEventListener('hashchange', this.handleHashChange.bind(this))
    }
    
    // Clean up any scroll listeners
    if (this.scrollableValue && this.hasTabsListTarget) {
      this.teardownTabScrolling()
    }
  }
  
  /**
   * Set appropriate ARIA attributes for accessibility
   */
  setupAccessibility() {
    if (this.hasTabsListTarget) {
      this.tabsListTarget.setAttribute('role', 'tablist')
      
      if (this.orientationValue === 'vertical') {
        this.tabsListTarget.setAttribute('aria-orientation', 'vertical')
      }
    }
    
    this.tabTargets.forEach((tab, index) => {
      // Set tab role
      tab.setAttribute('role', 'tab')
      
      // Create unique IDs if not present
      const tabId = this.getTabId(tab, index)
      const panelId = this.getPanelId(tabId)
      
      // Set ID if not already present
      if (!tab.id) {
        tab.id = tabId
      }
      
      // Set the panel this tab controls
      tab.setAttribute('aria-controls', panelId)
      
      // Set initial selected state
      tab.setAttribute('aria-selected', 'false')
      tab.setAttribute('tabindex', '-1')
      
      // If the panel exists, set its properties
      const panel = this.panelTargets[index]
      if (panel) {
        panel.setAttribute('role', 'tabpanel')
        panel.setAttribute('aria-labelledby', tabId)
        
        // Set ID if not already present
        if (!panel.id) {
          panel.id = panelId
        }
        
        // Initial state is hidden for all panels
        panel.setAttribute('aria-hidden', 'true')
      }
    })
  }
  
  /**
   * Initialize the tabs and select the active one
   */
  initializeTabs() {
    // Determine the initial active tab
    let initialTab = null
    
    // Check the URL hash first if hash syncing is enabled
    if (this.syncHashValue && window.location.hash) {
      const tabId = window.location.hash.substring(1)
      initialTab = this.findTabById(tabId)
      
      if (this.debugValue && !initialTab) {
        console.log(`Tab with ID '${tabId}' from URL hash not found`)
      }
    }
    
    // If no tab from hash, check localStorage if persistence is enabled
    if (!initialTab && this.persistValue) {
      const storedTabId = this.getStoredTabId()
      if (storedTabId) {
        initialTab = this.findTabById(storedTabId)
        
        if (this.debugValue && !initialTab) {
          console.log(`Tab with ID '${storedTabId}' from localStorage not found`)
        }
      }
    }
    
    // If still no active tab, check for a tab with active classes already applied
    if (!initialTab) {
      initialTab = this.tabTargets.find(tab => {
        return (
          tab.classList.contains('active-tab') || 
          tab.classList.contains('active') || 
          tab.getAttribute('aria-selected') === 'true'
        )
      })
    }
    
    // If still no active tab, check for the default tab from the data value
    if (!initialTab && this.hasDefaultTabValue) {
      if (this.isNumeric(this.defaultTabValue)) {
        // If defaultTab is a number, treat it as an index
        const index = parseInt(this.defaultTabValue)
        if (index >= 0 && index < this.tabTargets.length) {
          initialTab = this.tabTargets[index]
        }
      } else {
        // Otherwise treat it as an ID
        initialTab = this.findTabById(this.defaultTabValue)
      }
    }
    
    // If still no active tab, default to the first tab
    if (!initialTab && this.tabTargets.length > 0) {
      initialTab = this.tabTargets[0]
    }
    
    // Activate the determined tab without triggering animation
    // since this is the initial state
    if (initialTab) {
      this.activateTab(initialTab, false)
    }
  }
  
  /**
   * Handle tab selection when a tab is clicked
   */
  select(event) {
    const tab = event.currentTarget
    
    // Skip if the tab is disabled
    if (tab.hasAttribute('disabled') || tab.classList.contains('disabled')) {
      event.preventDefault()
      return
    }
    
    event.preventDefault()
    this.activateTab(tab, this.animateValue)
  }
  
  /**
   * Activate the specified tab
   * @param {HTMLElement} tab - The tab element to activate
   * @param {boolean} animate - Whether to animate the transition
   */
  activateTab(tab, animate = true) {
    // Find the index of the tab
    const index = this.tabTargets.indexOf(tab)
    if (index === -1) {
      console.warn("Tab not found in tabTargets", tab)
      return
    }
    
    // Get the corresponding panel
    const panel = this.panelTargets[index]
    if (!panel) {
      console.warn("No panel found for tab at index", index)
      return
    }
    
    // Get tab identity information for storage/sync
    const tabId = this.getTabId(tab, index)
    
    // Log if debug mode is enabled
    if (this.debugValue) {
      console.log(`Activating tab: ${tabId} at index ${index}`)
    }
    
    // Update active tab value
    this.activeTabValue = this.useIdsValue ? tabId : index.toString()
    
    // Store the active tab if persistence is enabled
    if (this.persistValue) {
      this.storeActiveTabId(tabId)
    }
    
    // Update URL hash if hash syncing is enabled
    if (this.syncHashValue) {
      this.updateUrlHash(tabId)
    }
    
    // Update all tab states
    this.updateTabStates(tab, panel, animate)
  }
  
  /**
   * Update the visual state of all tabs and panels
   */
  updateTabStates(activeTab, activePanel, animate) {
    // Update tab states
    this.tabTargets.forEach((tab, i) => {
      const isActive = tab === activeTab
      const panel = this.panelTargets[i]
      
      // Set aria attributes for accessibility
      tab.setAttribute('aria-selected', isActive ? 'true' : 'false')
      tab.setAttribute('tabindex', isActive ? '0' : '-1')
      
      // Apply appropriate classes based on the style
      this.updateTabClasses(tab, isActive)
      
      // Update panel visibility
      if (panel) {
        this.updatePanelVisibility(panel, isActive, animate)
      }
    })
    
    // Focus the active tab if it was activated via keyboard
    if (this.wasActivatedByKeyboard) {
      activeTab.focus()
      this.wasActivatedByKeyboard = false
    }
    
    // Scroll the tab into view if necessary
    if (this.scrollableValue && this.hasTabsListTarget) {
      this.scrollTabIntoView(activeTab)
    }
  }
  
  /**
   * Update the classes on a tab based on active state and style
   */
  updateTabClasses(tab, isActive) {
    // Common active state classes
    tab.classList.toggle('active-tab', isActive)
    tab.classList.toggle('active', isActive)
    
    // Add style-specific classes
    switch (this.styleValue) {
      case 'underline':
        // For underline/border bottom style (common in the Ghana Super App)
        if (isActive) {
          tab.classList.add('border-primary-500', 'dark:border-primary-400', 'text-primary-600', 'dark:text-primary-400')
          tab.classList.remove('border-transparent', 'text-gray-500', 'dark:text-gray-400')
        } else {
          tab.classList.remove('border-primary-500', 'dark:border-primary-400', 'text-primary-600', 'dark:text-primary-400')
          tab.classList.add('border-transparent', 'text-gray-500', 'dark:text-gray-400')
        }
        break
        
      case 'pills':
        // For pill style tabs
        if (isActive) {
          tab.classList.add('bg-primary-500', 'text-white')
          tab.classList.remove('bg-transparent', 'text-gray-500', 'dark:text-gray-400')
        } else {
          tab.classList.remove('bg-primary-500', 'text-white')
          tab.classList.add('bg-transparent', 'text-gray-500', 'dark:text-gray-400')
        }
        break
        
      case 'minimal':
        // For minimal style with just text color changes
        if (isActive) {
          tab.classList.add('text-primary-600', 'dark:text-primary-400', 'font-medium')
          tab.classList.remove('text-gray-500', 'dark:text-gray-400')
        } else {
          tab.classList.remove('text-primary-600', 'dark:text-primary-400', 'font-medium')
          tab.classList.add('text-gray-500', 'dark:text-gray-400')
        }
        break
        
      case 'boxed':
        // For boxed style tabs
        if (isActive) {
          tab.classList.add('bg-white', 'dark:bg-gray-800', 'shadow-sm', 'border-gray-200', 'dark:border-gray-700')
          tab.classList.remove('bg-gray-100', 'dark:bg-gray-700', 'border-transparent')
        } else {
          tab.classList.remove('bg-white', 'dark:bg-gray-800', 'shadow-sm', 'border-gray-200', 'dark:border-gray-700')
          tab.classList.add('bg-gray-100', 'dark:bg-gray-700', 'border-transparent')
        }
        break
        
      // Add more styles as needed
    }
  }
  
  /**
   * Update panel visibility with optional animation
   */
  updatePanelVisibility(panel, isVisible, animate) {
    panel.setAttribute('aria-hidden', !isVisible)
    
    if (animate && this.animateValue) {
      if (isVisible) {
        // Fade in animation
        panel.classList.remove('hidden')
        panel.style.opacity = '0'
        panel.style.transition = 'opacity 150ms ease-in-out'
        
        // Use a small delay to ensure the transition happens
        setTimeout(() => {
          panel.style.opacity = '1'
        }, 10)
        
        // Clean up after animation
        setTimeout(() => {
          panel.style.opacity = ''
          panel.style.transition = ''
        }, 160)
      } else {
        // Fade out animation
        panel.style.opacity = '0'
        panel.style.transition = 'opacity 150ms ease-in-out'
        
        // Hide after animation completes
        setTimeout(() => {
          panel.classList.add('hidden')
          panel.style.opacity = ''
          panel.style.transition = ''
        }, 150)
      }
    } else {
      // No animation
      panel.classList.toggle('hidden', !isVisible)
    }
  }
  
  /**
   * Handle keyboard navigation for tabs
   */
  keydown(event) {
    // Only react to keyboard events when a tab element has focus
    if (!this.tabTargets.includes(document.activeElement)) {
      return
    }
    
    const currentIndex = this.tabTargets.indexOf(document.activeElement)
    let nextIndex = null
    
    // Flag to indicate this activation was from keyboard for focus management
    this.wasActivatedByKeyboard = true
    
    switch (event.key) {
      case 'ArrowRight':
      case 'ArrowDown':
        // Move to next tab or wrap around to first
        nextIndex = (currentIndex + 1) % this.tabTargets.length
        break
        
      case 'ArrowLeft':
      case 'ArrowUp':
        // Move to previous tab or wrap around to last
        nextIndex = (currentIndex - 1 + this.tabTargets.length) % this.tabTargets.length
        break
        
      case 'Home':
        // Move to first tab
        nextIndex = 0
        break
        
      case 'End':
        // Move to last tab
        nextIndex = this.tabTargets.length - 1
        break
        
      case 'Enter':
      case ' ':
        // Activate current tab
        event.preventDefault()
        this.activateTab(this.tabTargets[currentIndex])
        return
        
      default:
        // Not a navigation key, do nothing
        return
    }
    
    // Prevent default behavior for handled keys
    event.preventDefault()
    
    // Activate the new tab
    const nextTab = this.tabTargets[nextIndex]
    this.activateTab(nextTab)
  }
  
  /**
   * Handle URL hash changes if sync is enabled
   */
  handleHashChange() {
    if (!this.syncHashValue) return
    
    const hash = window.location.hash.substring(1)
    if (hash) {
      const tab = this.findTabById(hash)
      if (tab) {
        this.activateTab(tab)
      }
    }
  }
  
  /**
   * Update the URL hash without triggering a scroll
   */
  updateUrlHash(id) {
    // Only update if syncing is enabled
    if (!this.syncHashValue) return
    
    // Update URL without scrolling
    const scrollPosition = window.scrollY
    window.location.hash = id
    window.scrollTo(window.scrollX, scrollPosition)
  }
  
  /**
   * Store active tab ID in localStorage if persistence is enabled
   */
  storeActiveTabId(id) {
    if (!this.persistValue) return
    
    try {
      const storageKey = `${this.storageKeyValue}-${this.element.id || 'default'}`
      localStorage.setItem(storageKey, id)
    } catch (e) {
      console.warn('Failed to store tab state in localStorage:', e)
    }
  }
  
  /**
   * Retrieve stored tab ID from localStorage
   */
  getStoredTabId() {
    if (!this.persistValue) return null
    
    try {
      const storageKey = `${this.storageKeyValue}-${this.element.id || 'default'}`
      return localStorage.getItem(storageKey)
    } catch (e) {
      console.warn('Failed to retrieve tab state from localStorage:', e)
      return null
    }
  }
  
  /**
   * Set up horizontal scrolling for tabs if needed
   */
  setupTabScrolling() {
    if (!this.hasTabsListTarget) return
    
    // Check if overflow scrolling is needed
    this.checkTabOverflow()
    
    // Add resize observer to check if overflow changes
    this.resizeObserver = new ResizeObserver(() => {
      this.checkTabOverflow()
    })
    
    this.resizeObserver.observe(this.tabsListTarget)
  }
  
  /**
   * Clean up scrolling event listeners
   */
  teardownTabScrolling() {
    if (this.resizeObserver) {
      this.resizeObserver.disconnect()
    }
  }
  
  /**
   * Check if tabs are overflowing and enable scrolling if needed
   */
  checkTabOverflow() {
    const tabsList = this.tabsListTarget
    
    // If the tab container is wider than the visible area, enable scrolling
    if (tabsList.scrollWidth > tabsList.clientWidth) {
      // Add necessary classes for horizontal scrolling
      tabsList.classList.add('overflow-x-auto', 'hide-scrollbar', 'flex-nowrap')
    } else {
      // Remove scrolling classes if not needed
      tabsList.classList.remove('overflow-x-auto', 'hide-scrollbar', 'flex-nowrap')
    }
  }
  
  /**
   * Scroll the active tab into view
   */
  scrollTabIntoView(tab) {
    if (!this.hasTabsListTarget) return
    
    // Only scroll if the tab list is scrollable
    if (this.tabsListTarget.scrollWidth > this.tabsListTarget.clientWidth) {
      // Calculate scroll position to center the tab
      const tabsList = this.tabsListTarget
      const tabRect = tab.getBoundingClientRect()
      const tabsListRect = tabsList.getBoundingClientRect()
      
      const scrollLeft = tab.offsetLeft - (tabsList.clientWidth / 2) + (tab.offsetWidth / 2)
      
      // Smoothly scroll to the tab
      tabsList.scrollTo({
        left: Math.max(0, scrollLeft),
        behavior: 'smooth'
      })
    }
  }
  
  // =================================================================
  // Utility methods
  // =================================================================
  
  /**
   * Get a tab by its ID
   */
  findTabById(id) {
    return this.tabTargets.find(tab => {
      return tab.id === id || 
             tab.getAttribute('data-tab-id') === id ||
             tab.getAttribute('data-id') === id
    })
  }
  
  /**
   * Get the ID for a tab element
   */
  getTabId(tab, index) {
    // Try to get existing ID
    return tab.id || 
           tab.getAttribute('data-tab-id') || 
           tab.getAttribute('data-id') || 
           `tab-${this.element.id || 'default'}-${index}`
  }
  
  /**
   * Get the ID for a panel based on tab ID
   */
  getPanelId(tabId) {
    return `panel-${tabId.replace(/^tab-/, '')}`
  }
  
  /**
   * Check if a string is numeric
   */
  isNumeric(str) {
    return /^\d+$/.test(str)
  }
  
  /**
   * Activate a tab by index - useful for external control
   */
  activateTabByIndex(index) {
    if (index >= 0 && index < this.tabTargets.length) {
      this.activateTab(this.tabTargets[index])
    } else {
      console.warn(`Tab index ${index} is out of range`)
    }
  }
  
  /**
   * Activate a tab by ID - useful for external control
   */
  activateTabById(id) {
    const tab = this.findTabById(id)
    if (tab) {
      this.activateTab(tab)
    } else {
      console.warn(`Tab with ID ${id} not found`)
    }
  }
  
  /**
   * Get the currently active tab index
   */
  get activeTabIndex() {
    const activeTab = this.tabTargets.find(tab => 
      tab.classList.contains('active-tab') || 
      tab.getAttribute('aria-selected') === 'true'
    )
    return activeTab ? this.tabTargets.indexOf(activeTab) : -1
  }
  
  /**
   * Get the currently active tab ID
   */
  get activeTabId() {
    const activeTab = this.tabTargets.find(tab => 
      tab.classList.contains('active-tab') || 
      tab.getAttribute('aria-selected') === 'true'
    )
    return activeTab ? this.getTabId(activeTab, this.tabTargets.indexOf(activeTab)) : null
  }
}