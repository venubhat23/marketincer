# AI Contract Generation Setup Guide

This guide will help you set up free AI services for contract generation.

## Free AI Services Available

### 1. Hugging Face (Recommended - Free Tier)
- **Free Credits**: Generous free tier with rate limits
- **Models**: Access to Llama, Qwen, and other open-source models
- **Setup**:
  1. Go to [huggingface.co](https://huggingface.co)
  2. Create an account
  3. Go to Settings → Access Tokens
  4. Create a new token with "Make calls to Inference Providers" permission
  5. Add to your Rails credentials or environment variables

### 2. Groq (Fast and Free)
- **Free Credits**: 14,400 tokens per minute free
- **Models**: Fast Llama models
- **Setup**:
  1. Go to [console.groq.com](https://console.groq.com)
  2. Create an account
  3. Go to API Keys section
  4. Create a new API key
  5. Add to your Rails credentials or environment variables

### 3. Together AI (Optional)
- **Free Credits**: $25 free credits on signup
- **Models**: Various open-source models
- **Setup**:
  1. Go to [together.ai](https://together.ai)
  2. Create an account
  3. Get API key from dashboard
  4. Add to your Rails credentials or environment variables

## Setting Up API Keys

### Option 1: Using Rails Credentials (Recommended)
```bash
# Edit credentials
EDITOR="nano" rails credentials:edit

# Add these lines:
huggingface_api_key: your_huggingface_token_here
groq_api_key: your_groq_api_key_here
together_api_key: your_together_api_key_here (optional)
openai_api_key: your_openai_key_here (optional)
```

### Option 2: Using Environment Variables
```bash
# Add to your .env file or environment
export HUGGINGFACE_API_KEY=your_huggingface_token_here
export GROQ_API_KEY=your_groq_api_key_here
export TOGETHER_API_KEY=your_together_api_key_here
export OPENAI_API_KEY=your_openai_key_here
```

## Testing the Setup

### 1. Test in Rails Console
```ruby
# Open Rails console
rails console

# Test the service
service = AiContractGenerationService.new("Create a simple service agreement for web development work")
result = service.generate
puts result
```

### 2. Test via API
```bash
# Test the API endpoint
curl -X POST http://localhost:3000/api/v1/contracts/generate_ai_contract \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Create a freelance web development contract for building an e-commerce website",
    "save_contract": true
  }'
```

## API Usage Examples

### Basic Contract Generation
```ruby
# In your controller or service
description = "Create an influencer collaboration agreement for Instagram posts"
service = AiContractGenerationService.new(description)
contract_content = service.generate
```

### With Different Contract Types
The service automatically detects contract types based on keywords:
- **Service Agreement**: "service", "freelance", "work", "project"
- **NDA**: "nda", "non-disclosure", "confidential"
- **Employment**: "employment", "job", "hire"
- **Influencer**: "influencer", "social media", "brand", "collaboration"
- **Sponsorship**: "sponsorship", "sponsor"
- **Gifting**: "gift", "product"

## Rate Limits and Best Practices

### Hugging Face
- **Free Tier**: 1,000 requests/month
- **Rate Limit**: ~10 requests/minute
- **Best Practice**: Primary service for most requests

### Groq
- **Free Tier**: 14,400 tokens/minute
- **Rate Limit**: Very generous
- **Best Practice**: Great for high-volume testing

### Fallback System
The service tries APIs in this order:
1. OpenAI (if configured)
2. Hugging Face Router
3. Groq
4. Together AI
5. Basic template generation (always works)

## Troubleshooting

### Common Issues

1. **"API key not found"**
   - Check your credentials setup
   - Verify environment variables are loaded
   - Restart your Rails server

2. **"Rate limit exceeded"**
   - The service will automatically try the next provider
   - Wait a few minutes and try again

3. **"Model not available"**
   - Service will try alternative models automatically
   - Check the logs for specific error messages

4. **"Empty response"**
   - Service will fall back to basic template
   - Try with a more detailed description

### Debug Mode
Enable detailed logging:
```ruby
# In your Rails console
Rails.logger.level = Logger::DEBUG

# Then test the service
service = AiContractGenerationService.new("your description")
result = service.generate
```

## Advanced Configuration

### Custom Models
You can modify the models used in the service:
```ruby
# In ai_contract_generation_service.rb
FREE_AI_SERVICES = [
  {
    name: 'Hugging Face Router',
    url: 'https://router.huggingface.co/v1/chat/completions',
    model: 'meta-llama/Llama-3.2-11B-Vision-Instruct', # Larger model
    api_key: HUGGINGFACE_API_KEY,
    type: 'openai_compatible'
  }
  # ... other services
]
```

### Custom Prompts
Modify the system prompt in the service for different contract styles:
```ruby
system_prompt = "You are a specialized legal assistant for [your industry]. Generate contracts that comply with [specific regulations]..."
```

## Support

If you encounter issues:
1. Check the Rails logs for detailed error messages
2. Verify your API keys are correct
3. Test each service individually
4. The service will always provide a fallback template even if all AI services fail

## Cost Monitoring

All the recommended services offer free tiers:
- **Hugging Face**: Free tier with rate limits
- **Groq**: Very generous free tier
- **Together AI**: $25 free credits

Monitor your usage in each provider's dashboard to avoid unexpected charges.