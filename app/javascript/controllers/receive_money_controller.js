import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "toast", 
    "toastMessage", 
    "requestAmount", 
    "requestPurpose", 
    "linkAmount", 
    "linkPurpose", 
    "linkExpiry"
  ]

  connect() {
    console.log("Receive Money controller connected")
    this.accountName = this.element.dataset.receiveMoneyAccountName
    this.accountNumber = this.element.dataset.receiveMoneyAccountNumber
    this.bankName = this.element.dataset.receiveMoneyBankName
    this.paymentLink = this.element.dataset.receiveMoneyPaymentLink
  }

  // Copy to clipboard functionality
  copyToClipboard(event) {
    const textToCopy = event.currentTarget.dataset.copyText
    
    if (!textToCopy) return
    
    navigator.clipboard.writeText(textToCopy)
      .then(() => {
        this.showToast("Copied to clipboard!")
      })
      .catch((error) => {
        console.error("Copy failed:", error)
        this.showToast("Failed to copy. Please try again.")
      })
  }
  
  // Show toast notification
  showToast(message) {
    this.toastMessageTarget.textContent = message
    this.toastTarget.classList.remove("hidden")
    
    setTimeout(() => {
      this.toastTarget.classList.add("hidden")
    }, 3000)
  }
  
  // QR Code Generator for specific amount
  generateAmountQR() {
    const amount = this.requestAmountTarget.value
    const purpose = this.requestPurposeTarget.value
    
    if (!amount || parseFloat(amount) <= 0) {
      this.showToast("Please enter a valid amount")
      return
    }
    
    // Call to backend endpoint to generate a QR code with amount
    fetch(`/api/wallet/generate_qr?amount=${amount}&purpose=${encodeURIComponent(purpose)}`, {
      method: 'GET',
      headers: {
        'Accept': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      }
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        // Reload the current page with the new QR code
        window.location.href = `/wallet/receive_money?active_tab=qr_code&amount=${amount}&purpose=${encodeURIComponent(purpose)}`
      } else {
        this.showToast(data.error || "Failed to generate QR code")
      }
    })
    .catch(error => {
      console.error("Error generating QR code:", error)
      this.showToast("An error occurred. Please try again.")
    })
  }

  // Download QR Code
  downloadQRCode() {
    // Find the SVG element
    const svgElement = document.querySelector('.qr-code-container svg')
    
    if (!svgElement) {
      this.showToast("QR code not found")
      return
    }
    
    // Create a canvas element
    const canvas = document.createElement('canvas')
    const context = canvas.getContext('2d')
    
    // Set canvas dimensions to match QR code (with some padding)
    canvas.width = svgElement.width.baseVal.value + 40
    canvas.height = svgElement.height.baseVal.value + 40
    
    // Fill with white background
    context.fillStyle = '#FFFFFF'
    context.fillRect(0, 0, canvas.width, canvas.height)
    
    // Convert SVG to data URL
    const svgData = new XMLSerializer().serializeToString(svgElement)
    const img = new Image()
    
    img.onload = () => {
      // Draw the image centered on the canvas
      context.drawImage(img, 20, 20)
      
      // Convert to data URL and download
      const dataUrl = canvas.toDataURL('image/png')
      const link = document.createElement('a')
      link.download = `payment-qr-${this.accountNumber}.png`
      link.href = dataUrl
      link.click()
    }
    
    img.src = 'data:image/svg+xml;base64,' + btoa(svgData)
  }

  // Share QR Code
  shareQRCode() {
    // Check if Web Share API is available
    if (!navigator.share) {
      this.showToast("Sharing is not available on your device")
      return
    }
    
    // Get account information for sharing
    const shareText = `Send money to ${this.accountName} (Acc: ${this.accountNumber}) via ${this.bankName}.`
    
    // Share the information
    navigator.share({
      title: 'Payment QR Code',
      text: shareText,
      url: this.paymentLink
    })
    .catch(error => {
      console.error('Error sharing:', error)
    })
  }

  // Generate custom payment link
  generateCustomLink() {
    const amount = this.linkAmountTarget.value
    const purpose = this.linkPurposeTarget.value
    const expiry = this.linkExpiryTarget.value
    
    // Call to backend to generate custom link
    fetch('/api/wallet/generate_payment_link', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({
        amount: amount,
        purpose: purpose,
        expiry: expiry
      })
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        // Reload the current page with the new payment link
        window.location.href = `/wallet/receive_money?active_tab=payment_link&link_id=${data.link_id}`
      } else {
        this.showToast(data.error || "Failed to generate payment link")
      }
    })
    .catch(error => {
      console.error("Error generating payment link:", error)
      this.showToast("An error occurred. Please try again.")
    })
  }

  // Delete payment link
  deletePaymentLink(event) {
    const linkId = event.currentTarget.dataset.linkId
    
    if (!confirm("Are you sure you want to delete this payment link?")) {
      return
    }
    
    fetch(`/api/wallet/payment_links/${linkId}`, {
      method: 'DELETE',
      headers: {
        'Accept': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      }
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        // Remove the link element from DOM or reload the page
        const linkElement = event.currentTarget.closest('.payment-link-item')
        if (linkElement) {
          linkElement.remove()
        } else {
          window.location.reload()
        }
        this.showToast("Payment link deleted")
      } else {
        this.showToast(data.error || "Failed to delete payment link")
      }
    })
    .catch(error => {
      console.error("Error deleting payment link:", error)
      this.showToast("An error occurred. Please try again.")
    })
  }

  // Focus on custom link creation
  focusCustomLink() {
    // Switch to payment link tab
    const paymentLinkTab = document.querySelector('[data-tab-id="payment_link"]')
    if (paymentLinkTab) {
      paymentLinkTab.click()
    }
    
    // Focus on amount field
    setTimeout(() => {
      this.linkAmountTarget.focus()
    }, 300)
  }

  // Share methods for different platforms
  shareViaWhatsApp(event) {
    const shareType = event.currentTarget.dataset.shareType || 'account'
    let shareText = ''
    
    if (shareType === 'link') {
      shareText = `Send money to me using this payment link: ${this.paymentLink}`
    } else {
      shareText = `Send money to my account:\nName: ${this.accountName}\nAccount: ${this.accountNumber}\nBank: ${this.bankName}`
    }
    
    window.open(`https://wa.me/?text=${encodeURIComponent(shareText)}`)
  }
  
  shareViaSMS(event) {
    const shareType = event.currentTarget.dataset.shareType || 'account'
    let shareText = ''
    
    if (shareType === 'link') {
      shareText = `Send money to me using this payment link: ${this.paymentLink}`
    } else {
      shareText = `Send money to my account: Name: ${this.accountName}, Account: ${this.accountNumber}, Bank: ${this.bankName}`
    }
    
    // Use SMS URI scheme if available, otherwise fallback to clipboard
    if (/android|iphone|ipad|ipod/i.test(navigator.userAgent)) {
      window.location.href = `sms:?body=${encodeURIComponent(shareText)}`
    } else {
      navigator.clipboard.writeText(shareText)
        .then(() => this.showToast("Copied to clipboard! You can now paste in your SMS app."))
        .catch(() => this.showToast("Couldn't copy text. Please try again."))
    }
  }
  
  shareViaEmail(event) {
    const shareType = event.currentTarget.dataset.shareType || 'account'
    let subject = 'Payment Details'
    let body = ''
    
    if (shareType === 'link') {
      body = `Hello,\n\nPlease use the following link to send money to me:\n\n${this.paymentLink}\n\nThank you!`
    } else {
      body = `Hello,\n\nPlease use the following details to send money to my account:\n\nName: ${this.accountName}\nAccount Number: ${this.accountNumber}\nBank: ${this.bankName}\n\nThank you!`
    }
    
    window.location.href = `mailto:?subject=${encodeURIComponent(subject)}&body=${encodeURIComponent(body)}`
  }
  
  shareViaOther(event) {
    const shareType = event.currentTarget.dataset.shareType || 'account'
    let shareText = ''
    
    if (shareType === 'link') {
      shareText = `Send money to me using this payment link: ${this.paymentLink}`
    } else {
      shareText = `Send money to my account:\nName: ${this.accountName}\nAccount: ${this.accountNumber}\nBank: ${this.bankName}`
    }
    
    // Use Web Share API if available
    if (navigator.share) {
      navigator.share({
        title: 'Payment Details',
        text: shareText
      })
      .catch(error => console.error('Error sharing:', error))
    } else {
      // Fallback to clipboard
      navigator.clipboard.writeText(shareText)
        .then(() => this.showToast("Copied to clipboard!"))
        .catch(() => this.showToast("Couldn't copy text. Please try again."))
    }
  }
}