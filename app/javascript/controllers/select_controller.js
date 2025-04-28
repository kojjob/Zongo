import { Controller } from "@hotwired/stimulus"

// Controller for handling select dropdowns with server-side saving
export default class extends Controller {
  static targets = ["select"]
  static values = {
    setting: String,
    url: { type: String, default: '/user_settings/update_appearance' }
  }

  connect() {
    console.log("Select controller connected")
    
    // Add change event listener to the select element
    if (this.hasSelectTarget) {
      this.selectTarget.addEventListener('change', this.handleChange.bind(this))
    }
  }
  
  handleChange(event) {
    const value = event.target.value
    const settingName = this.settingValue || event.target.name
    
    console.log(`Setting ${settingName} to: ${value}`)
    
    // Save the setting to the server
    this.saveSetting(settingName, value)
  }
  
  saveSetting(settingName, value) {
    // Create form data
    const formData = new FormData()
    
    // Format the setting name properly for the server
    // If it's a nested attribute like user[settings][language], handle it properly
    if (settingName.includes('[')) {
      formData.append(settingName, value)
    } else {
      formData.append(`user[settings][${settingName}]`, value)
    }
    
    // Send AJAX request
    fetch(this.urlValue, {
      method: 'PATCH',
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
      this.showNotification(`${this.getSettingLabel(settingName)} updated successfully`, 'success')
      
      // Apply the setting immediately if needed
      this.applySettingImmediately(settingName, value)
    })
    .catch(error => {
      console.error(`Error saving setting ${settingName}:`, error)
      
      // Show an error message
      this.showNotification(`Failed to update ${this.getSettingLabel(settingName)}`, 'error')
    })
  }
  
  getSettingLabel(settingName) {
    // Extract the base setting name from potentially nested attributes
    const baseName = settingName.includes('[') 
      ? settingName.match(/\[([^\]]+)\](?!.*\[)/)[1] 
      : settingName
    
    // Convert setting_name to a readable label
    const labels = {
      'language': 'Language',
      'currency_display': 'Currency display',
      'theme_preference': 'Theme'
    }
    
    return labels[baseName] || baseName
  }
  
  applySettingImmediately(settingName, value) {
    // Extract the base setting name from potentially nested attributes
    const baseName = settingName.includes('[') 
      ? settingName.match(/\[([^\]]+)\](?!.*\[)/)[1] 
      : settingName
    
    // Apply certain settings immediately
    if (baseName === 'language') {
      // For language changes, we might need to reload the page
      // or update specific text elements
      document.documentElement.lang = value
    } else if (baseName === 'currency_display') {
      // For currency display, we might update currency formatting
      document.dispatchEvent(new CustomEvent('currencyChanged', {
        detail: { currency: value }
      }))
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
