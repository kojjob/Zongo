import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["icon"]

  connect() {
    console.log("Icon controller connected")
    this.fixMissingIcons()
  }

  fixMissingIcons() {
    // Get all SVG icons in the document
    const svgIcons = document.querySelectorAll('svg[class*="h-"]')
    
    svgIcons.forEach(svg => {
      // Check if the SVG has no children (which indicates it might be broken)
      if (svg.children.length === 0) {
        // Get the icon name from the parent element's data attribute or try to infer it
        const iconName = this.inferIconName(svg)
        
        if (iconName) {
          // Create a new SVG with the proper structure
          this.replaceBrokenIcon(svg, iconName)
        }
      }
    })
  }

  inferIconName(svg) {
    // Try to infer the icon name from the parent element's text content
    const parentText = svg.parentElement.textContent.trim().toLowerCase()
    
    // Map of common text to icon names
    const iconMap = {
      'dashboard': 'chart-bar',
      'users': 'users',
      'transactions': 'currency-dollar',
      'events': 'calendar',
      'loans': 'credit-card',
      'system': 'server',
      'notifications': 'bell',
      'overview': 'view-grid',
      'analytics': 'chart-bar',
      'help center': 'question-mark-circle',
      'new action': 'plus',
      'sign out': 'logout'
    }
    
    // Check if any of the keys in the map are in the parent text
    for (const [key, value] of Object.entries(iconMap)) {
      if (parentText.includes(key)) {
        return value
      }
    }
    
    // Default fallback
    return 'document-text'
  }

  replaceBrokenIcon(svg, iconName) {
    // Create a new use element that references the icon from the sprite
    const use = document.createElementNS('http://www.w3.org/2000/svg', 'use')
    use.setAttributeNS('http://www.w3.org/1999/xlink', 'xlink:href', `#icon-${iconName}`)
    
    // Clear the SVG and add the use element
    svg.innerHTML = ''
    svg.appendChild(use)
    
    // Add the necessary attributes for the SVG to display properly
    svg.setAttribute('fill', 'currentColor')
    
    // Log the fix for debugging
    console.log(`Fixed missing icon: ${iconName}`)
  }
}
