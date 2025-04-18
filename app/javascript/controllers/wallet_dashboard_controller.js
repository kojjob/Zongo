import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["balanceDisplay", "maskedBalance", "eyeIcon", "eyeOffIcon", "moreActions"]
  
  // Toggle balance visibility
  toggleBalance() {
    this.balanceDisplayTarget.classList.toggle('hidden')
    this.maskedBalanceTarget.classList.toggle('hidden')
    this.eyeIconTarget.classList.toggle('hidden')
    this.eyeOffIconTarget.classList.toggle('hidden')
  }
  
  // Toggle more actions visibility
  toggleMoreActions() {
    this.moreActionsTarget.classList.toggle('hidden')
  }
  
  // Copy account ID to clipboard
  copyAccountId(event) {
    const accountId = '<%= @wallet.wallet_id %>'
    navigator.clipboard.writeText(accountId).then(() => {
      // Show tooltip or notification
      const button = event.currentTarget
      const originalHTML = button.innerHTML
      
      // Change to checkmark icon
      button.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" /></svg>'
      
      // Revert after 2 seconds
      setTimeout(() => {
        button.innerHTML = originalHTML
      }, 2000)
    })
  }
}
