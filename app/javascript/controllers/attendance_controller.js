import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  toggle(event) {
    event.preventDefault()
    
    const eventId = this.element.dataset.attendanceEventId
    const isAttending = this.element.querySelector('svg').classList.contains('text-green-500')
    
    const url = isAttending ? 
      `/events/${eventId}/cancel_attendance` : 
      `/events/${eventId}/attend`
    
    fetch(url, {
      method: isAttending ? 'DELETE' : 'POST',
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      credentials: 'same-origin'
    })
    .then(response => {
      if (response.ok) {
        const icon = this.element.querySelector('svg')
        
        if (isAttending) {
          // Change to "attend" icon
          icon.classList.remove('text-green-500')
          icon.classList.add('text-gray-500', 'dark:text-gray-300')
          icon.innerHTML = '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path>'
        } else {
          // Change to "attending" icon
          icon.classList.remove('text-gray-500', 'dark:text-gray-300')
          icon.classList.add('text-green-500')
          icon.innerHTML = '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>'
        }
        
        // Refresh the page to update attendee counts
        window.location.reload()
      }
    })
    .catch(error => console.error('Error:', error))
  }
}
