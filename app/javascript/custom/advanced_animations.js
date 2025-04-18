// Advanced animations and micro-interactions for the landing page

document.addEventListener('DOMContentLoaded', function() {
  // Make all elements visible immediately
  const revealElements = document.querySelectorAll('.js-reveal, .js-reveal-left, .js-reveal-right');
  revealElements.forEach(element => {
    element.classList.add('is-visible');
  });

  // Initialize FAQ accordions
  initFaqAccordions();
});

// Helper function to check if element is in viewport
function isElementInViewport(el) {
  const rect = el.getBoundingClientRect();
  return (
    rect.top <= (window.innerHeight || document.documentElement.clientHeight) * 0.85 &&
    rect.bottom >= 0
  );
}

// Throttle function to limit scroll event firing
function throttle(func, delay) {
  let lastCall = 0;
  return function(...args) {
    const now = new Date().getTime();
    if (now - lastCall < delay) {
      return;
    }
    lastCall = now;
    return func(...args);
  };
}

// Add delighter dots to specific sections
function addDelighterDots() {
  const sections = document.querySelectorAll('.landing-page section');

  sections.forEach(section => {
    // Add 3-5 delighter dots per section
    const dotCount = Math.floor(Math.random() * 3) + 3;

    for (let i = 0; i < dotCount; i++) {
      const dot = document.createElement('div');
      dot.classList.add('delighter-dot');

      // Random position within the section
      const top = Math.floor(Math.random() * 100);
      const left = Math.floor(Math.random() * 100);

      dot.style.top = `${top}%`;
      dot.style.left = `${left}%`;

      // Random delay for animation
      dot.style.animationDelay = `${Math.random() * 5}s`;

      section.appendChild(dot);
    }
  });
}

// Initialize stat counters with animation
function initStatCounters() {
  const statElements = document.querySelectorAll('.stat-counter');

  statElements.forEach(stat => {
    const targetValue = parseInt(stat.getAttribute('data-value'), 10);
    const suffix = stat.getAttribute('data-suffix') || '';
    const duration = 2000; // 2 seconds
    const startTime = Date.now();
    const startValue = 0;

    function updateCounter() {
      const currentTime = Date.now();
      const elapsedTime = currentTime - startTime;

      if (elapsedTime < duration) {
        const value = Math.floor(easeOutQuart(elapsedTime, startValue, targetValue, duration));
        stat.textContent = value + suffix;
        requestAnimationFrame(updateCounter);
      } else {
        stat.textContent = targetValue + suffix;
      }
    }

    // Only start counter when element is in viewport
    const observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          requestAnimationFrame(updateCounter);
          observer.unobserve(entry.target);
        }
      });
    }, { threshold: 0.5 });

    observer.observe(stat);
  });
}

// Easing function for smooth counter animation
function easeOutQuart(t, b, c, d) {
  return -c * ((t = t / d - 1) * t * t * t - 1) + b;
}

// Initialize FAQ accordions
function initFaqAccordions() {
  const accordions = document.querySelectorAll('.faq-accordion');

  accordions.forEach(accordion => {
    const header = accordion.querySelector('.faq-accordion-header');

    header.addEventListener('click', () => {
      // Toggle active class
      accordion.classList.toggle('active');

      // Close other accordions
      accordions.forEach(otherAccordion => {
        if (otherAccordion !== accordion && otherAccordion.classList.contains('active')) {
          otherAccordion.classList.remove('active');
        }
      });
    });
  });
}

// Initialize parallax effect for hero section
function initParallax() {
  const heroSection = document.querySelector('.landing-page section:first-child');
  const parallaxElements = heroSection.querySelectorAll('.bg-pattern');

  window.addEventListener('scroll', throttle(() => {
    const scrollPosition = window.pageYOffset;

    parallaxElements.forEach((element, index) => {
      // Different speeds for different elements
      const speed = 0.1 + (index * 0.05);
      const yPos = -(scrollPosition * speed);

      element.style.transform = `translate3d(0, ${yPos}px, 0)`;
    });
  }, 10));
}

// Custom cursor disabled for now
