  import { Controller } from "@hotwired/stimulus"

  export default class extends Controller {
    static targets = ["input", "label", "errorText", "validIcon", "errorIcon"]
    
    static values = {
      hasValue: Boolean,
      valid: Boolean
    }
    
    connect() {
      this.updateVisualState()
    }
    
    onInput() {
      this.hasValueValue = this.inputTarget.value.length > 0
      this.updateVisualState()
    }
    
    onFocus() {
      this.element.classList.add("is-focused")
    }
    
    onBlur() {
      this.element.classList.remove("is-focused")
      this.validate()
    }
    
    validate() {
      // Basic validation - customize as needed
      const value = this.inputTarget.value
      const required = this.inputTarget.required
      
      this.validValue = !(required && !value)
      
      this.updateVisualState()
    }
    
    updateVisualState() {
      // Handle floating label animation
      if (this.hasValueValue) {
        this.labelTarget.classList.add("-translate-y-5", "scale-75")
        this.labelTarget.classList.add("text-primary-600", "dark:text-primary-400")
      } else {
        this.labelTarget.classList.remove("-translate-y-5", "scale-75")
        this.labelTarget.classList.remove("text-primary-600", "dark:text-primary-400")
      }
      
      // Handle validation state icons
      if (this.hasValueValue) {
        if (this.validValue) {
          this.validIconTarget.classList.remove("hidden")
          this.errorIconTarget.classList.add("hidden")
        } else {
          this.validIconTarget.classList.add("hidden")
          this.errorIconTarget.classList.remove("hidden")
        }
      } else {
        this.validIconTarget.classList.add("hidden")
        this.errorIconTarget.classList.add("hidden")
      }
    }
  }