import React, { useState, useEffect } from 'react';
import styled from 'styled-components';
import { motion } from 'framer-motion';

const HeaderContainer = styled(motion.header)`
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  background: rgba(10, 10, 10, 0.95);
  backdrop-filter: blur(10px);
  z-index: 1000;
  padding: 1rem 0;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
  transition: background 0.3s ease;
`;

const Nav = styled.nav`
  display: flex;
  justify-content: space-between;
  align-items: center;
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 20px;
`;

const Brand = styled.h2`
  color: #ffffff;
  font-weight: 700;
  font-size: 1.5rem;
`;

const NavLinks = styled.ul`
  display: flex;
  gap: 2rem;
  
  @media (max-width: 768px) {
    position: absolute;
    top: 100%;
    left: 0;
    right: 0;
    background: rgba(10, 10, 10, 0.98);
    flex-direction: column;
    padding: 1rem;
    border-top: 1px solid rgba(255, 255, 255, 0.1);
    transform: translateY(-100%);
    opacity: 0;
    visibility: hidden;
    transition: all 0.3s ease;
    
    &.active {
      transform: translateY(0);
      opacity: 1;
      visibility: visible;
    }
  }
`;

const NavLink = styled.a`
  color: rgba(255, 255, 255, 0.8);
  font-weight: 500;
  transition: color 0.3s ease;
  
  &:hover {
    color: #ffffff;
  }
`;

const CTAButton = styled(motion.button)`
  background: linear-gradient(45deg, #667eea 0%, #764ba2 100%);
  color: white;
  padding: 0.75rem 1.5rem;
  border-radius: 25px;
  font-weight: 500;
  
  &:hover {
    transform: translateY(-2px);
    box-shadow: 0 10px 25px rgba(102, 126, 234, 0.3);
  }
`;

const MobileToggle = styled.button`
  display: none;
  background: none;
  color: white;
  font-size: 1.5rem;
  padding: 0.5rem;
  
  @media (max-width: 768px) {
    display: block;
  }
`;

const Header = () => {
  const [isScrolled, setIsScrolled] = useState(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  useEffect(() => {
    const handleScroll = () => {
      setIsScrolled(window.scrollY > 50);
    };

    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  const scrollToSection = (sectionId) => {
    const element = document.getElementById(sectionId);
    if (element) {
      element.scrollIntoView({ behavior: 'smooth' });
      setMobileMenuOpen(false);
    }
  };

  return (
    <HeaderContainer
      initial={{ y: -100 }}
      animate={{ y: 0 }}
      transition={{ duration: 0.6 }}
      style={{
        background: isScrolled ? 'rgba(10, 10, 10, 0.98)' : 'rgba(10, 10, 10, 0.95)'
      }}
    >
      <Nav>
        <Brand>Brand</Brand>
        <NavLinks className={mobileMenuOpen ? 'active' : ''}>
          <li><NavLink onClick={() => scrollToSection('features')}>Features</NavLink></li>
          <li><NavLink onClick={() => scrollToSection('about')}>About</NavLink></li>
          <li><NavLink onClick={() => scrollToSection('pricing')}>Pricing</NavLink></li>
          <li><NavLink onClick={() => scrollToSection('contact')}>Contact</NavLink></li>
        </NavLinks>
        <CTAButton
          whileHover={{ scale: 1.05 }}
          whileTap={{ scale: 0.95 }}
        >
          Get Started
        </CTAButton>
        <MobileToggle onClick={() => setMobileMenuOpen(!mobileMenuOpen)}>
          ☰
        </MobileToggle>
      </Nav>
    </HeaderContainer>
  );
};

export default Header;