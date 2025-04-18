// Simple lightbox functionality
document.addEventListener('DOMContentLoaded', function() {
  // Define global functions for lightbox
  window.openLightbox = function(src) {
    const lightbox = document.getElementById('lightbox');
    const lightboxImg = document.getElementById('lightbox-img');
    
    if (lightbox && lightboxImg) {
      lightboxImg.src = src;
      lightbox.classList.remove('hidden');
      document.body.classList.add('overflow-hidden');
    }
  };
  
  window.closeLightbox = function() {
    const lightbox = document.getElementById('lightbox');
    
    if (lightbox) {
      lightbox.classList.add('hidden');
      document.body.classList.remove('overflow-hidden');
    }
  };
  
  // Close lightbox when clicking outside the image
  const lightbox = document.getElementById('lightbox');
  if (lightbox) {
    lightbox.addEventListener('click', function(e) {
      if (e.target === this) {
        closeLightbox();
      }
    });
    
    // Close lightbox when pressing Escape key
    document.addEventListener('keydown', function(e) {
      if (e.key === 'Escape' && !lightbox.classList.contains('hidden')) {
        closeLightbox();
      }
    });
  }
});
