import { Controller } from "@hotwired/stimulus"

// This controller handles countdown timers for flash sales and promotions
export default class extends Controller {
  static targets = ["days", "hours", "minutes", "seconds"]
  static values = { endsAt: String }
  
  connect() {
    this.endTime = new Date(this.endsAtValue).getTime()
    this.updateCountdown()
    this.timer = setInterval(() => this.updateCountdown(), 1000)
  }
  
  disconnect() {
    if (this.timer) {
      clearInterval(this.timer)
    }
  }
  
  updateCountdown() {
    const now = new Date().getTime()
    const distance = this.endTime - now
    
    if (distance <= 0) {
      // Timer has ended
      this.setTimerValues(0, 0, 0, 0)
      clearInterval(this.timer)
      
      // Optionally reload the page or update UI
      if (this.hasTimerEndedValue && this.timerEndedValue === 'reload') {
        window.location.reload()
      }
      
      return
    }
    
    // Calculate time units
    const days = Math.floor(distance / (1000 * 60 * 60 * 24))
    const hours = Math.floor((distance % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60))
    const minutes = Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60))
    const seconds = Math.floor((distance % (1000 * 60)) / 1000)
    
    this.setTimerValues(days, hours, minutes, seconds)
  }
  
  setTimerValues(days, hours, minutes, seconds) {
    if (this.hasDaysTarget) {
      this.daysTarget.textContent = this.padZero(days)
    }
    
    if (this.hasHoursTarget) {
      this.hoursTarget.textContent = this.padZero(hours)
    }
    
    if (this.hasMinutesTarget) {
      this.minutesTarget.textContent = this.padZero(minutes)
    }
    
    if (this.hasSecondsTarget) {
      this.secondsTarget.textContent = this.padZero(seconds)
    }
  }
  
  padZero(num) {
    return num.toString().padStart(2, '0')
  }
}
