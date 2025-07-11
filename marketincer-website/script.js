// Smooth scrolling for navigation links
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            target.scrollIntoView({
                behavior: 'smooth',
                block: 'start'
            });
        }
    });
});

// Header scroll effect
window.addEventListener('scroll', function() {
    const header = document.querySelector('.header');
    if (window.scrollY > 50) {
        header.style.backgroundColor = 'rgba(243, 243, 243, 0.95)';
        header.style.boxShadow = '0 4px 32px rgba(0, 0, 0, 0.1)';
    } else {
        header.style.backgroundColor = 'rgba(243, 243, 243, 0.82)';
        header.style.boxShadow = 'none';
    }
});

// Mobile menu toggle
const mobileMenuButton = document.createElement('button');
mobileMenuButton.innerHTML = '☰';
mobileMenuButton.className = 'mobile-menu-toggle';
mobileMenuButton.style.cssText = `
    display: none;
    background: none;
    border: none;
    font-size: 24px;
    cursor: pointer;
    color: var(--text-dark);
    padding: 10px;
`;

// Add mobile menu toggle to header
document.querySelector('.header-controls').appendChild(mobileMenuButton);

// Mobile menu functionality
mobileMenuButton.addEventListener('click', function() {
    const mobileMenu = document.querySelector('.mobile-menu');
    mobileMenu.classList.toggle('active');
});

// Close mobile menu when clicking on a link
document.querySelectorAll('.mobile-nav-link').forEach(link => {
    link.addEventListener('click', function() {
        document.querySelector('.mobile-menu').classList.remove('active');
    });
});

// Intersection Observer for animations
const observerOptions = {
    threshold: 0.1,
    rootMargin: '0px 0px -50px 0px'
};

const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            entry.target.style.opacity = '1';
            entry.target.style.transform = 'translateY(0)';
        }
    });
}, observerOptions);

// Observe elements for animation
document.addEventListener('DOMContentLoaded', function() {
    const animateElements = document.querySelectorAll('.benefit-item, .feature-card, .feature-showcase');
    animateElements.forEach(el => {
        el.style.opacity = '0';
        el.style.transform = 'translateY(30px)';
        el.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
        observer.observe(el);
    });
});

// Button hover effects
document.querySelectorAll('.btn').forEach(button => {
    button.addEventListener('mouseenter', function() {
        this.style.transform = 'translateY(-2px)';
    });
    
    button.addEventListener('mouseleave', function() {
        this.style.transform = 'translateY(0)';
    });
});

// Responsive mobile menu display
function handleResize() {
    if (window.innerWidth <= 768) {
        mobileMenuButton.style.display = 'block';
        document.querySelector('.nav-links').style.display = 'none';
    } else {
        mobileMenuButton.style.display = 'none';
        document.querySelector('.nav-links').style.display = 'flex';
        document.querySelector('.mobile-menu').classList.remove('active');
    }
}

window.addEventListener('resize', handleResize);
handleResize(); // Call on load

// Stat counter animation
function animateCounters() {
    const counters = document.querySelectorAll('.stat-number');
    counters.forEach(counter => {
        const target = parseInt(counter.textContent.replace(/[^\d]/g, ''));
        const increment = target / 100;
        let current = 0;
        
        const updateCounter = () => {
            if (current < target) {
                current += increment;
                counter.textContent = '+' + Math.floor(current) + (counter.textContent.includes('k') ? 'k' : '');
                requestAnimationFrame(updateCounter);
            } else {
                counter.textContent = '+' + target + (counter.textContent.includes('k') ? 'k' : '');
            }
        };
        
        updateCounter();
    });
}

// Trigger counter animation when stat cards are visible
const statObserver = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            setTimeout(() => {
                animateCounters();
            }, 500);
            statObserver.unobserve(entry.target);
        }
    });
}, observerOptions);

document.addEventListener('DOMContentLoaded', function() {
    const statCards = document.querySelectorAll('.stat-card');
    statCards.forEach(card => {
        statObserver.observe(card);
    });
});
