  import { Controller } from "@hotwired/stimulus"

  export default class extends Controller {
    static targets = ["input", "toggleButton", "showIcon", "hideIcon", "strengthBar", "strengthMeter"]
    
    toggleVisibility(event) {
      event.preventDefault()
      
      const type = this.inputTarget.type === 'password' ? 'text' : 'password'
      this.inputTarget.type = type
      
      this.showIconTarget.classList.toggle('hidden')
      this.hideIconTarget.classList.toggle('hidden')
    }
    
    checkStrength() {
      if (!this.hasStrengthBarTarget) return
      
      const password = this.inputTarget.value
      let strength = 0
      
      // Calculate password strength
      if (password.length >= 8) strength += 1
      if (password.match(/[a-z]/) && password.match(/[A-Z]/)) strength += 1
      if (password.match(/[0-9]/)) strength += 1
      if (password.match(/[^a-zA-Z0-9]/)) strength += 1
      
      // Update strength meter
      let percentage = (strength / 4) * 100
      let color = 'bg-red-500'
      
      if (percentage >= 75) color = 'bg-green-500'
      else if (percentage >= 50) color = 'bg-yellow-500'
      else if (percentage >= 25) color = 'bg-orange-500'
      
      this.strengthBarTarget.style.width = `${percentage}%`
      this.strengthBarTarget.className = `h-full transition-all duration-500 ease-out ${color}`
    }
  }