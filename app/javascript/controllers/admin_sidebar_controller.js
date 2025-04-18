import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="admin-sidebar"
export default class extends Controller {
  connect() {
    // Check if sidebar state is stored in localStorage
    const sidebarCollapsed = localStorage.getItem('admin-sidebar-collapsed') === 'true'

    if (sidebarCollapsed) {
      this.collapse()
    }

    // Handle responsive layout on initial load
    this.handleResponsiveLayout()

    // Add resize listener for responsive behavior
    window.addEventListener('resize', this.handleResponsiveLayout.bind(this))
  }

  disconnect() {
    // Remove resize listener when controller disconnects
    window.removeEventListener('resize', this.handleResponsiveLayout.bind(this))
  }

  toggle() {
    const sidebar = this.element

    if (window.innerWidth < 1024) {
      // Mobile behavior - toggle open class and overlay
      sidebar.classList.toggle('open')

      if (sidebar.classList.contains('open')) {
        this.createOverlay()
      } else {
        this.removeOverlay()
      }
    } else {
      // Desktop behavior - toggle collapsed state
      if (sidebar.classList.contains('collapsed')) {
        this.expand()
      } else {
        this.collapse()
      }
    }
  }

  collapse() {
    const sidebar = this.element
    const content = document.querySelector('.admin-content')
    const textElements = sidebar.querySelectorAll('.sidebar-text')

    sidebar.classList.add('collapsed')
    content.classList.add('expanded')
    textElements.forEach(el => el.classList.add('hidden'))

    localStorage.setItem('admin-sidebar-collapsed', 'true')
  }

  expand() {
    const sidebar = this.element
    const content = document.querySelector('.admin-content')
    const textElements = sidebar.querySelectorAll('.sidebar-text')

    sidebar.classList.remove('collapsed')
    content.classList.remove('expanded')
    textElements.forEach(el => el.classList.remove('hidden'))

    localStorage.setItem('admin-sidebar-collapsed', 'false')
  }

  handleResponsiveLayout() {
    const sidebar = this.element
    const content = document.querySelector('.admin-content')

    if (window.innerWidth < 1024) {
      // Mobile layout - sidebar is hidden by default
      sidebar.classList.remove('open')
      this.removeOverlay()

      // Reset any inline styles that might have been applied
      content.style.marginLeft = ''
      content.style.width = ''

      // Make sure we're using the CSS classes for responsive layout
      sidebar.classList.remove('collapsed')
      content.classList.remove('expanded')
    } else {
      // Desktop layout - respect user preference
      const sidebarCollapsed = localStorage.getItem('admin-sidebar-collapsed') === 'true'

      if (sidebarCollapsed) {
        this.collapse()
      } else {
        this.expand()
      }

      // Remove mobile overlay if we resize to desktop
      this.removeOverlay()
    }
  }

  createOverlay() {
    // Create a dark overlay behind the sidebar on mobile
    if (!this.overlay) {
      this.overlay = document.createElement('div')
      this.overlay.classList.add('fixed', 'inset-0', 'bg-gray-900', 'bg-opacity-50', 'z-40', 'transition-opacity', 'duration-300')
      this.overlay.setAttribute('data-action', 'click->admin-sidebar#toggle')
      document.body.appendChild(this.overlay)

      // Fade in the overlay
      setTimeout(() => {
        this.overlay.classList.add('opacity-100')
      }, 10)
    }
  }

  removeOverlay() {
    // Remove the overlay if it exists
    if (this.overlay) {
      // Fade out the overlay
      this.overlay.classList.remove('opacity-100')
      this.overlay.classList.add('opacity-0')

      // Remove after transition
      setTimeout(() => {
        if (this.overlay && this.overlay.parentNode) {
          document.body.removeChild(this.overlay)
          this.overlay = null
        }
      }, 300)
    }
  }
}
