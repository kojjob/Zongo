// Simple accordion implementation for FAQ section

document.addEventListener('DOMContentLoaded', function() {
  // Get all FAQ accordion items
  const accordionItems = document.querySelectorAll('.faq-accordion');
  
  // Add click event listeners to each accordion header
  accordionItems.forEach(item => {
    const header = item.querySelector('button');
    const content = item.querySelector('[data-accordion-target="content"]');
    const icon = item.querySelector('svg');
    
    // Initially hide all content
    if (content) {
      content.style.display = 'none';
    }
    
    // Add click event listener
    if (header) {
      header.addEventListener('click', function(e) {
        e.preventDefault();
        
        // Toggle content visibility
        if (content) {
          const isVisible = content.style.display === 'block';
          
          // Hide all other accordion contents
          accordionItems.forEach(otherItem => {
            const otherContent = otherItem.querySelector('[data-accordion-target="content"]');
            const otherIcon = otherItem.querySelector('svg');
            
            if (otherContent && otherItem !== item) {
              otherContent.style.display = 'none';
              if (otherIcon) {
                otherIcon.classList.remove('rotate-180');
              }
            }
          });
          
          // Toggle current accordion
          content.style.display = isVisible ? 'none' : 'block';
          
          // Toggle icon rotation
          if (icon) {
            if (isVisible) {
              icon.classList.remove('rotate-180');
            } else {
              icon.classList.add('rotate-180');
            }
          }
        }
      });
    }
  });
});
