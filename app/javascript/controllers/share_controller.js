// app/javascript/controllers/share_controller.js
import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="share"
export default class extends Controller {
  static values = {
    url: String,
    title: String,
    text: String
  }
  
  connect() {
    console.log("Share controller connected", {
      url: this.urlValue,
      title: this.titleValue,
      text: this.textValue
    });
  }
  
  shareEvent(event) {
    event.preventDefault();
    event.stopPropagation(); // Prevent the event from bubbling to the card link
    
    const shareData = {
      title: this.titleValue,
      text: this.textValue,
      url: this.urlValue
    };
    
    // Check if Web Share API is available
    if (navigator.share && !navigator.userAgent.match(/Firefox/i)) {  // Firefox has a buggy implementation
      navigator.share(shareData)
        .then(() => console.log('Shared successfully'))
        .catch((error) => this.fallbackShare(error));
    } else {
      this.fallbackShare();
    }
  }
  
  fallbackShare(error) {
    if (error) console.log('Error sharing:', error);
    
    // Create a temporary input to copy the URL
    const input = document.createElement('input');
    document.body.appendChild(input);
    input.value = this.urlValue;
    input.select();
    
    try {
      // Copy the URL to clipboard
      document.execCommand('copy');
      
      // Show tooltip or notification
      const tooltip = document.createElement('div');
      tooltip.textContent = 'Link copied to clipboard!';
      tooltip.className = 'fixed bottom-4 left-1/2 transform -translate-x-1/2 bg-gray-800 text-white px-4 py-2 rounded-lg shadow-lg text-sm z-50';
      document.body.appendChild(tooltip);
      
      // Remove tooltip after 2 seconds
      setTimeout(() => {
        tooltip.remove();
      }, 2000);
    } catch (err) {
      console.error('Failed to copy:', err);
      alert('Could not copy link. Please try again.');
    }
    
    // Clean up
    document.body.removeChild(input);
  }
}
