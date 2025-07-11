import React from 'react';
import styled from 'styled-components';
import { motion } from 'framer-motion';

const PricingSection = styled.section`
  padding: 100px 0;
  background: #0a0a0a;
`;

const Container = styled.div`
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 20px;
`;

const SectionHeader = styled.div`
  text-align: center;
  margin-bottom: 4rem;
`;

const Title = styled(motion.h2)`
  font-size: 2.5rem;
  font-weight: 700;
  color: #ffffff;
  margin-bottom: 1rem;
  
  @media (max-width: 768px) {
    font-size: 2rem;
  }
`;

const Description = styled(motion.p)`
  font-size: 1.1rem;
  color: rgba(255, 255, 255, 0.7);
`;

const PricingGrid = styled.div`
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 2rem;
  margin-top: 4rem;
`;

const PricingCard = styled(motion.div)`
  background: rgba(255, 255, 255, 0.03);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 20px;
  padding: 2.5rem;
  text-align: center;
  position: relative;
  transition: all 0.3s ease;
  backdrop-filter: blur(10px);
  
  &:hover {
    transform: translateY(-10px);
    border-color: rgba(102, 126, 234, 0.3);
  }
  
  &.featured {
    border-color: #667eea;
    box-shadow: 0 20px 40px rgba(102, 126, 234, 0.2);
  }
`;

const PricingBadge = styled.div`
  position: absolute;
  top: -10px;
  left: 50%;
  transform: translateX(-50%);
  background: linear-gradient(45deg, #667eea 0%, #764ba2 100%);
  color: white;
  padding: 0.5rem 1rem;
  border-radius: 20px;
  font-size: 0.8rem;
  font-weight: 600;
`;

const PricingHeader = styled.div`
  margin-bottom: 2rem;
`;

const PlanName = styled.h3`
  color: #ffffff;
  font-size: 1.5rem;
  font-weight: 600;
  margin-bottom: 1rem;
`;

const Price = styled.div`
  margin-bottom: 2rem;
`;

const PriceAmount = styled.span`
  font-size: 3rem;
  font-weight: 700;
  color: #ffffff;
`;

const PricePeriod = styled.span`
  font-size: 1rem;
  color: rgba(255, 255, 255, 0.7);
`;

const FeaturesList = styled.ul`
  margin-bottom: 2rem;
  text-align: left;
`;

const Feature = styled.li`
  color: rgba(255, 255, 255, 0.8);
  padding: 0.5rem 0;
  font-size: 0.95rem;
`;

const PricingButton = styled(motion.button)`
  width: 100%;
  background: linear-gradient(45deg, #667eea 0%, #764ba2 100%);
  color: white;
  padding: 1rem 2rem;
  border-radius: 30px;
  font-weight: 600;
  transition: all 0.3s ease;
  
  &:hover {
    transform: translateY(-2px);
    box-shadow: 0 8px 25px rgba(102, 126, 234, 0.3);
  }
`;

const Pricing = () => {
  const plans = [
    {
      name: 'Starter',
      price: '$19',
      period: '/month',
      features: [
        '✓ 5 Projects',
        '✓ 10GB Storage',
        '✓ Basic Support',
        '✓ SSL Certificate'
      ],
      buttonText: 'Get Started'
    },
    {
      name: 'Professional',
      price: '$49',
      period: '/month',
      features: [
        '✓ 50 Projects',
        '✓ 100GB Storage',
        '✓ Priority Support',
        '✓ Advanced Analytics',
        '✓ Custom Domain'
      ],
      buttonText: 'Get Started',
      featured: true
    },
    {
      name: 'Enterprise',
      price: '$99',
      period: '/month',
      features: [
        '✓ Unlimited Projects',
        '✓ 1TB Storage',
        '✓ 24/7 Support',
        '✓ White-label Solution',
        '✓ API Access'
      ],
      buttonText: 'Contact Sales'
    }
  ];

  const containerVariants = {
    hidden: { opacity: 0 },
    visible: {
      opacity: 1,
      transition: {
        staggerChildren: 0.2
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
    <PricingSection id="pricing">
      <Container>
        <SectionHeader>
          <Title
            initial={{ y: 20, opacity: 0 }}
            whileInView={{ y: 0, opacity: 1 }}
            transition={{ duration: 0.6 }}
            viewport={{ once: true }}
          >
            Choose your plan
          </Title>
          <Description
            initial={{ y: 20, opacity: 0 }}
            whileInView={{ y: 0, opacity: 1 }}
            transition={{ duration: 0.6, delay: 0.2 }}
            viewport={{ once: true }}
          >
            Simple, transparent pricing that grows with you
          </Description>
        </SectionHeader>
        
        <motion.div
          variants={containerVariants}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true }}
        >
          <PricingGrid>
            {plans.map((plan, index) => (
              <PricingCard
                key={index}
                variants={itemVariants}
                className={plan.featured ? 'featured' : ''}
              >
                {plan.featured && <PricingBadge>Most Popular</PricingBadge>}
                <PricingHeader>
                  <PlanName>{plan.name}</PlanName>
                  <Price>
                    <PriceAmount>{plan.price}</PriceAmount>
                    <PricePeriod>{plan.period}</PricePeriod>
                  </Price>
                </PricingHeader>
                <FeaturesList>
                  {plan.features.map((feature, featureIndex) => (
                    <Feature key={featureIndex}>{feature}</Feature>
                  ))}
                </FeaturesList>
                <PricingButton
                  whileHover={{ scale: 1.05 }}
                  whileTap={{ scale: 0.95 }}
                >
                  {plan.buttonText}
                </PricingButton>
              </PricingCard>
            ))}
          </PricingGrid>
        </motion.div>
      </Container>
    </PricingSection>
  );
};

export default Pricing;