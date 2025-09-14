import React from 'react';
import styled from 'styled-components';
import { motion } from 'framer-motion';

const HeroSection = styled.section`
  display: flex;
  align-items: center;
  min-height: 100vh;
  padding: 120px 0 80px;
  background: linear-gradient(135deg, #0a0a0a 0%, #1a1a1a 100%);
  position: relative;
  overflow: hidden;
  
  &::before {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: radial-gradient(circle at 30% 40%, rgba(102, 126, 234, 0.1) 0%, transparent 50%);
  }
  
  @media (max-width: 768px) {
    flex-direction: column;
    text-align: center;
    gap: 2rem;
    padding: 100px 0 60px;
  }
`;

const HeroContent = styled.div`
  flex: 1;
  z-index: 2;
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 20px;
  display: flex;
  align-items: center;
  
  @media (max-width: 768px) {
    flex-direction: column;
    text-align: center;
  }
`;

const Content = styled.div`
  flex: 1;
  
  @media (max-width: 768px) {
    margin-bottom: 2rem;
  }
`;

const Title = styled(motion.h1)`
  font-size: 4rem;
  font-weight: 700;
  color: #ffffff;
  line-height: 1.1;
  margin-bottom: 1.5rem;
  
  @media (max-width: 768px) {
    font-size: 2.5rem;
  }
  
  @media (max-width: 480px) {
    font-size: 2rem;
  }
`;

const Subtitle = styled(motion.p)`
  font-size: 1.25rem;
  color: rgba(255, 255, 255, 0.8);
  margin-bottom: 2rem;
  line-height: 1.6;
  
  @media (max-width: 768px) {
    font-size: 1.1rem;
  }
`;

const ButtonGroup = styled(motion.div)`
  display: flex;
  gap: 1rem;
  
  @media (max-width: 768px) {
    flex-direction: column;
    width: 100%;
    
    button {
      width: 100%;
    }
  }
`;

const HeroImage = styled.div`
  flex: 1;
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 2;
  
  @media (max-width: 768px) {
    width: 100%;
    max-width: 350px;
  }
`;

const CodeCard = styled(motion.div)`
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 15px;
  padding: 1.5rem;
  backdrop-filter: blur(10px);
  width: 400px;
  box-shadow: 0 20px 40px rgba(0, 0, 0, 0.3);
  
  @media (max-width: 768px) {
    width: 100%;
    max-width: 350px;
  }
`;

const CardHeader = styled.div`
  display: flex;
  justify-content: flex-start;
  margin-bottom: 1rem;
`;

const Dots = styled.div`
  display: flex;
  gap: 0.5rem;
`;

const Dot = styled.span`
  width: 12px;
  height: 12px;
  border-radius: 50%;
  
  &.red { background-color: #ff5f56; }
  &.yellow { background-color: #ffbd2e; }
  &.green { background-color: #27ca3f; }
`;

const CodeContent = styled.div`
  font-family: 'Monaco', monospace;
  font-size: 0.9rem;
  line-height: 1.8;
`;

const CodeLine = styled.div`
  color: #ffffff;
  margin-bottom: 0.5rem;
  
  &.indent {
    margin-left: 2rem;
  }
  
  .keyword { color: #ff79c6; }
  .variable { color: #50fa7b; }
  .operator { color: #ff79c6; }
  .string { color: #f1fa8c; }
  .function { color: #8be9fd; }
  .bracket { color: #bd93f9; }
`;

const Hero = () => {
  const containerVariants = {
    hidden: { opacity: 0 },
    visible: {
      opacity: 1,
      transition: {
        staggerChildren: 0.2,
        duration: 0.6
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
    <HeroSection>
      <HeroContent>
        <Content>
          <motion.div
            variants={containerVariants}
            initial="hidden"
            animate="visible"
          >
            <Title variants={itemVariants}>
              Build the future with{' '}
              <span className="gradient-text">modern tools</span>
            </Title>
            <Subtitle variants={itemVariants}>
              Transform your ideas into reality with our cutting-edge platform.
              Join thousands of creators who are already building the next big thing.
            </Subtitle>
            <ButtonGroup variants={itemVariants}>
              <motion.button
                className="btn-primary"
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
              >
                Start Building
              </motion.button>
              <motion.button
                className="btn-secondary"
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
              >
                Watch Demo
              </motion.button>
            </ButtonGroup>
          </motion.div>
        </Content>
        
        <HeroImage>
          <CodeCard
            initial={{ x: 100, opacity: 0 }}
            animate={{ x: 0, opacity: 1 }}
            transition={{ duration: 0.8, delay: 0.3 }}
          >
            <CardHeader>
              <Dots>
                <Dot className="red" />
                <Dot className="yellow" />
                <Dot className="green" />
              </Dots>
            </CardHeader>
            <CodeContent>
              <CodeLine>
                <span className="keyword">const</span>{' '}
                <span className="variable">future</span>{' '}
                <span className="operator">=</span>{' '}
                <span className="string">'amazing'</span>
              </CodeLine>
              <CodeLine>
                <span className="keyword">function</span>{' '}
                <span className="function">buildDreams</span>
                <span className="bracket">()</span>{' '}
                <span className="bracket">{'{'}</span>
              </CodeLine>
              <CodeLine className="indent">
                <span className="keyword">return</span>{' '}
                <span className="string">'success'</span>
              </CodeLine>
              <CodeLine>
                <span className="bracket">{'}'}</span>
              </CodeLine>
            </CodeContent>
          </CodeCard>
        </HeroImage>
      </HeroContent>
    </HeroSection>
  );
};

export default Hero;