import React from 'react';
import styled from 'styled-components';
import { motion } from 'framer-motion';

const FooterWrapper = styled.footer`
  background: #0a0a0a;
  padding: 60px 0 20px;
  border-top: 1px solid rgba(255, 255, 255, 0.1);
`;

const Container = styled.div`
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 20px;
`;

const FooterContent = styled.div`
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 2rem;
  margin-bottom: 2rem;
  
  @media (max-width: 768px) {
    grid-template-columns: repeat(2, 1fr);
  }
  
  @media (max-width: 480px) {
    grid-template-columns: 1fr;
  }
`;

const FooterSection = styled(motion.div)`
  h4 {
    color: #ffffff;
    font-weight: 600;
    margin-bottom: 1rem;
  }
  
  ul {
    list-style: none;
  }
  
  li {
    margin-bottom: 0.5rem;
  }
  
  a {
    color: rgba(255, 255, 255, 0.7);
    text-decoration: none;
    transition: color 0.3s ease;
    
    &:hover {
      color: #ffffff;
    }
  }
`;

const FooterBottom = styled.div`
  text-align: center;
  padding-top: 2rem;
  border-top: 1px solid rgba(255, 255, 255, 0.1);
  color: rgba(255, 255, 255, 0.5);
`;

const Footer = () => {
  const footerSections = [
    {
      title: 'Product',
      links: [
        { name: 'Features', href: '#features' },
        { name: 'Pricing', href: '#pricing' },
        { name: 'API', href: '#' },
        { name: 'Documentation', href: '#' }
      ]
    },
    {
      title: 'Company',
      links: [
        { name: 'About', href: '#about' },
        { name: 'Careers', href: '#' },
        { name: 'Blog', href: '#' },
        { name: 'Press', href: '#' }
      ]
    },
    {
      title: 'Support',
      links: [
        { name: 'Help Center', href: '#' },
        { name: 'Contact', href: '#contact' },
        { name: 'Status', href: '#' },
        { name: 'Community', href: '#' }
      ]
    },
    {
      title: 'Legal',
      links: [
        { name: 'Privacy', href: '#' },
        { name: 'Terms', href: '#' },
        { name: 'Cookies', href: '#' },
        { name: 'Licenses', href: '#' }
      ]
    }
  ];

  const containerVariants = {
    hidden: { opacity: 0 },
    visible: {
      opacity: 1,
      transition: {
        staggerChildren: 0.1
      }
    }
  };

  const itemVariants = {
    hidden: { y: 20, opacity: 0 },
    visible: {
      y: 0,
      opacity: 1,
      transition: {
        duration: 0.6
      }
    }
  };

  return (
    <FooterWrapper>
      <Container>
        <motion.div
          variants={containerVariants}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true }}
        >
          <FooterContent>
            {footerSections.map((section, index) => (
              <FooterSection key={index} variants={itemVariants}>
                <h4>{section.title}</h4>
                <ul>
                  {section.links.map((link, linkIndex) => (
                    <li key={linkIndex}>
                      <a href={link.href}>{link.name}</a>
                    </li>
                  ))}
                </ul>
              </FooterSection>
            ))}
          </FooterContent>
        </motion.div>
        
        <FooterBottom>
          <p>&copy; 2024 Brand. All rights reserved.</p>
        </FooterBottom>
      </Container>
    </FooterWrapper>
  );
};

export default Footer;