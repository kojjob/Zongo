import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

// Connects to data-controller="notifications"
export default class extends Controller {
  static targets = [
    "count", 
    "list", 
    "emptyState", 
    "panel", 
    "badge", 
    "toast", 
    "toastContainer"
  ]
  
  static values = {
    userId: Number,
    autoHideToast: { type: Boolean, default: true },
    toastDuration: { type: Number, default: 5000 }
  }
  
  connect() {
    console.log("Notifications controller connected")
    
    if (this.hasUserIdValue) {
      this.connectToChannel()
    }
    
    // Store bound functions as instance properties to allow proper cleanup
    this.boundCloseIfClickedOutside = this.closeIfClickedOutside.bind(this)
    this.boundHandleKeyDown = this.handleKeyDown.bind(this)
    
    // Close panel when clicking outside
    document.addEventListener('click', this.boundCloseIfClickedOutside)
    
    // Close panel when pressing escape
    document.addEventListener('keydown', this.boundHandleKeyDown)
  }
  
  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
    
    document.removeEventListener('click', this.boundCloseIfClickedOutside)
    document.removeEventListener('keydown', this.boundHandleKeyDown)
    
    // Clear any pending toast timers
    if (this.toastTimers) {
      this.toastTimers.forEach(timer => clearTimeout(timer))
    }
  }
  
  connectToChannel() {
    this.subscription = createConsumer().subscriptions.create(
      { channel: "NotificationsChannel" },
      {
        connected: this.channelConnected.bind(this),
        disconnected: this.channelDisconnected.bind(this),
        received: this.channelReceived.bind(this)
      }
    )
  }
  
  channelConnected() {
    console.log("Connected to notifications channel")
  }
  
  channelDisconnected() {
    console.log("Disconnected from notifications channel")
  }
  
  channelReceived(data) {
    console.log("Received notification data:", data)
    
    if (data.type === 'unread_count') {
      this.updateUnreadCount(data.count)
    } else if (data.type === 'notification') {
      this.handleNewNotification(data)
    }
  }
  
  updateUnreadCount(count) {
    if (this.hasCountTarget) {
      this.countTarget.textContent = count
      
      // Show/hide badge based on count
      if (this.hasBadgeTarget) {
        if (count > 0) {
          this.badgeTarget.classList.remove('hidden')
        } else {
          this.badgeTarget.classList.add('hidden')
        }
      }
    }
  }
  
  handleNewNotification(data) {
    // Add notification to list if list target exists
    if (this.hasListTarget && data.html) {
      // Hide empty state if it exists
      if (this.hasEmptyStateTarget) {
        this.emptyStateTarget.classList.add('hidden')
      }
      
      // Add notification to list
      this.listTarget.insertAdjacentHTML('afterbegin', data.html)
      
      // Update count
      this.updateUnreadCount(data.unread_count || parseInt(this.countTarget.textContent || '0') + 1)
    }
    
    // Show toast notification if it's critical or configured to show toasts
    if (data.severity === 'critical' || data.show_toast) {
      this.showToast(data)
    }
  }
  
  showToast(data) {
    if (!this.hasToastTarget || !this.hasToastContainerTarget) return
    
    // Clone the toast template
    const toast = this.toastTarget.cloneNode(true)
    toast.classList.remove('hidden')
    toast.id = `toast-${Date.now()}`
    
    // Set toast content
    toast.querySelector('[data-notification-title]').textContent = data.title
    toast.querySelector('[data-notification-message]').textContent = data.message
    
    // Set severity class
    const severityClass = this.getSeverityClass(data.severity)
    toast.classList.add(severityClass)
    
    // Add action button if needed
    if (data.action_url) {
      const actionButton = toast.querySelector('[data-notification-action]')
      if (actionButton) {
        actionButton.classList.remove('hidden')
        actionButton.href = data.action_url
        actionButton.textContent = data.action_text || 'View'
      }
    }
    
    // Add to container
    this.toastContainerTarget.appendChild(toast)
    
    // Auto-hide toast after duration
    if (this.autoHideToastValue) {
      this.toastTimers = this.toastTimers || []
      const timer = setTimeout(() => {
        this.hideToast(toast.id)
      }, this.toastDurationValue)
      this.toastTimers.push(timer)
    }
    
    return toast.id
  }
  
  hideToast(toastId) {
    const toast = document.getElementById(toastId)
    if (toast) {
      toast.classList.add('opacity-0')
      setTimeout(() => {
        toast.remove()
      }, 300)
    }
  }
  
  getSeverityClass(severity) {
    switch (severity) {
      case 'critical':
        return 'bg-red-100 dark:bg-red-900/30 border-red-400 dark:border-red-800 text-red-700 dark:text-red-300'
      case 'warning':
        return 'bg-yellow-100 dark:bg-yellow-900/30 border-yellow-400 dark:border-yellow-800 text-yellow-700 dark:text-yellow-300'
      default:
        return 'bg-blue-100 dark:bg-blue-900/30 border-blue-400 dark:border-blue-800 text-blue-700 dark:text-blue-300'
    }
  }
  
  toggle() {
    if (this.hasPanelTarget) {
      this.panelTarget.classList.toggle('hidden')
      
      if (!this.panelTarget.classList.contains('hidden')) {
        // Mark notifications as read when panel is opened
        this.markAllAsRead()
      }
    }
  }
  
  close() {
    if (this.hasPanelTarget) {
      this.panelTarget.classList.add('hidden')
    }
  }
  
  closeIfClickedOutside(event) {
    if (this.hasPanelTarget && !this.panelTarget.classList.contains('hidden')) {
      // Check if click is outside the panel and not on the toggle button
      if (!this.panelTarget.contains(event.target) && 
          !event.target.closest('[data-action*="notifications#toggle"]')) {
        this.close()
      }
    }
  }
  
  handleKeyDown(event) {
    if (event.key === 'Escape' && this.hasPanelTarget && !this.panelTarget.classList.contains('hidden')) {
      this.close()
    }
  }
  
  markAsRead(event) {
    const notificationId = event.currentTarget.dataset.notificationId
    
    if (notificationId && this.subscription) {
      this.subscription.perform('mark_as_read', { id: notificationId })
      
      // Update UI immediately
      const notification = event.currentTarget.closest('[data-notification]')
      if (notification) {
        notification.classList.remove('unread')
        notification.classList.add('read')
      }
    }
    
    // Prevent default if it's a link
    if (event.currentTarget.tagName === 'A') {
      event.preventDefault()
    }
  }
  
  markAllAsRead() {
    if (this.subscription) {
      this.subscription.perform('mark_all_as_read')
      
      // Update UI immediately
      if (this.hasListTarget) {
        this.listTarget.querySelectorAll('[data-notification].unread').forEach(notification => {
          notification.classList.remove('unread')
          notification.classList.add('read')
        })
      }
      
      // Update count
      this.updateUnreadCount(0)
    }
  }
  
  dismissToast(event) {
    const toast = event.currentTarget.closest('[data-toast]')
    if (toast) {
      this.hideToast(toast.id)
    }
  }
}
