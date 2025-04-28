import { Controller } from "@hotwired/stimulus"

// Enhanced toggle controller for accessibility settings
export default class extends Controller {
  static targets = ["checkbox", "label"]
  static values = {
    setting: String,
    url: { type: String, default: '/user_settings/toggle_setting' }
  }

  connect() {
    console.log("Toggle controller connected")

    // Initialize the toggle state
    if (this.hasCheckboxTarget) {
      this.updateToggleAppearance()
    }
  }

  toggle(event) {
    // Prevent the default behavior if this was triggered by a click
    if (event) {
      event.preventDefault()
    }

    if (this.hasCheckboxTarget) {
      // Toggle the checkbox
      this.checkboxTarget.checked = !this.checkboxTarget.checked

      // Update the appearance
      this.updateToggleAppearance()

      // Save the setting to the server
      if (this.hasSetting) {
        this.saveSetting()
      }
    }
  }

  updateToggleAppearance() {
    // Update the toggle appearance based on the checkbox state
    if (this.hasLabelTarget) {
      if (this.checkboxTarget.checked) {
        this.labelTarget.classList.add('bg-indigo-600')
        this.labelTarget.classList.remove('bg-gray-300')
      } else {
        this.labelTarget.classList.remove('bg-indigo-600')
        this.labelTarget.classList.add('bg-gray-300')
      }
    }
  }

  saveSetting() {
    // Get the setting name and value
    const settingName = this.settingValue
    const settingValue = this.checkboxTarget.checked

    // Create form data
    const formData = new FormData()
    formData.append('setting_name', settingName)
    formData.append('value', settingValue)

    // Send AJAX request
    fetch(this.urlValue, {
      method: 'POST',
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest'
      },
      body: formData
    })
    .then(response => {
      if (!response.ok) {
        throw new Error('Network response was not ok')
      }
      return response.json()
    })
    .then(data => {
      console.log(`Setting ${settingName} saved:`, data)

      // Show a success message
      this.showNotification(`${this.getSettingLabel(settingName)} ${settingValue ? 'enabled' : 'disabled'}`, 'success')

      // Apply the setting immediately if needed
      this.applySettingImmediately(settingName, settingValue)
    })
    .catch(error => {
      console.error(`Error saving setting ${settingName}:`, error)

      // Show an error message
      this.showNotification(`Failed to save setting`, 'error')

      // Revert the toggle
      this.checkboxTarget.checked = !this.checkboxTarget.checked
      this.updateToggleAppearance()
    })
  }

  getSettingLabel(settingName) {
    // Convert setting_name to a readable label
    const labels = {
      'reduce_motion': 'Reduce motion',
      'high_contrast': 'High contrast mode',
      'text_size': 'Text size'
    }

    return labels[settingName] || settingName
  }

  applySettingImmediately(settingName, value) {
    // Apply certain settings immediately
    if (settingName === 'reduce_motion') {
      document.documentElement.classList.toggle('reduce-motion', value)
    } else if (settingName === 'high_contrast') {
      document.documentElement.classList.toggle('high-contrast', value)
    }
  }

  showNotification(message, type = 'info') {
    // Create notification element
    const notification = document.createElement('div')
    notification.className = `fixed bottom-4 right-4 px-6 py-3 rounded-lg shadow-lg z-50 ${
      type === 'success' ? 'bg-green-500 text-white' :
      type === 'error' ? 'bg-red-500 text-white' :
      'bg-blue-500 text-white'
    }`
    notification.style.transition = 'all 0.3s ease-in-out'
    notification.style.opacity = '0'
    notification.style.transform = 'translateY(20px)'

    // Add icon based on type
    const icon = document.createElement('i')
    icon.className = `fas fa-${
      type === 'success' ? 'check-circle' :
      type === 'error' ? 'exclamation-circle' :
      'info-circle'
    } mr-2`
    notification.appendChild(icon)

    // Add message text
    const text = document.createTextNode(message)
    notification.appendChild(text)

    // Add to DOM
    document.body.appendChild(notification)

    // Trigger animation
    setTimeout(() => {
      notification.style.opacity = '1'
      notification.style.transform = 'translateY(0)'
    }, 10)

    // Remove after delay
    setTimeout(() => {
      notification.style.opacity = '0'
      notification.style.transform = 'translateY(20px)'

      setTimeout(() => {
        document.body.removeChild(notification)
      }, 300)
    }, 3000)
  }
}
