# Content Generation API Documentation

## Overview
The `handleGenerateWithAI` function integrates with the Marketincer AI content generation API to automatically create social media post content.

## API Endpoint
```
POST https://api.marketincer.com/api/v1/generate-content
```

## Authentication
- **Type**: Bearer Token
- **Header**: `Authorization: Bearer {token}`
- **Token Source**: Retrieved from `localStorage.getItem("token")`

## Request Format

### Headers
```json
{
  "Authorization": "Bearer YOUR_JWT_TOKEN_HERE",
  "Content-Type": "application/json"
}
```

### Request Body
```json
{
  "description": "generate note on social media"
}
```

### Sample Request (JavaScript)
```javascript
const handleGenerateWithAI = async () => {
  setGeneratingContent(true);
  try {
    const token = localStorage.getItem("token");
    const response = await axios.post(
      "https://api.marketincer.com/api/v1/generate-content",
      {
        description: "generate note on social media"
      },
      {
        headers: {
          Authorization: `Bearer ${token}`,
          "Content-Type": "application/json"
        }
      }
    );

    // Handle response
    const generatedContent = response.data.content || response.data.message || response.data;
    setPostContent(generatedContent);

  } catch (error) {
    console.error("Error generating content:", error);
  } finally {
    setGeneratingContent(false);
  }
};
```

## Response Format

### Success Response (200 OK)
```json
{
  "success": true,
  "content": "🚀 Boost your social media presence with engaging content! Here are 5 tips to increase your reach: 1) Post consistently 2) Use relevant hashtags 3) Engage with your audience 4) Share valuable insights 5) Collaborate with others. What's your favorite social media strategy? #SocialMediaTips #DigitalMarketing #ContentCreation",
  "timestamp": "2024-01-15T10:30:00Z",
  "usage": {
    "tokens_used": 150,
    "remaining_credits": 850
  }
}
```

### Alternative Success Response Format
```json
{
  "message": "Looking to elevate your social media game? 📱✨ Start with authentic storytelling, engage genuinely with your community, and don't forget to showcase your brand's personality! Remember: consistency beats perfection every time. #SocialMediaStrategy #BrandBuilding #ContentMarketing",
  "status": "success"
}
```

### Error Response (400 Bad Request)
```json
{
  "error": "Invalid request",
  "message": "Description is required",
  "code": "MISSING_DESCRIPTION"
}
```

### Error Response (401 Unauthorized)
```json
{
  "error": "Unauthorized",
  "message": "Invalid or expired token",
  "code": "INVALID_TOKEN"
}
```

### Error Response (429 Too Many Requests)
```json
{
  "error": "Rate limit exceeded",
  "message": "You have exceeded your API rate limit. Please try again later.",
  "code": "RATE_LIMIT_EXCEEDED",
  "retry_after": 60
}
```

### Error Response (500 Internal Server Error)
```json
{
  "error": "Internal server error",
  "message": "An unexpected error occurred while generating content",
  "code": "GENERATION_ERROR"
}
```

## Response Handling

The function handles multiple response formats by checking for content in this order:
1. `response.data.content`
2. `response.data.message`  
3. `response.data` (fallback)

## UI Integration

### Button States
- **Default State**: Shows company logo and "Generate with AI" text
- **Loading State**: Shows spinner and "Generating..." text
- **Disabled State**: Button is disabled during content generation

### Logo Implementation
The button now displays the Marketincer company logo instead of the letter "M":
```jsx
<img 
  src="/marketincer.jpg" 
  alt="Marketincer Logo" 
  style={{
    width: '100%',
    height: '100%',
    objectFit: 'contain'
  }}
/>
```

## Error Handling
- Network errors are caught and logged to console
- User receives error toast notification
- Loading state is properly reset in finally block
- Button remains functional after errors

## Usage Notes
- The function sets `generatingContent` state to show loading UI
- Generated content is automatically inserted into the post editor
- Success toast notification is shown when content is generated
- The description parameter accepts any text input from the frontend

## AI Service Integration

### Primary AI Service: Groq API
- **Model**: `llama3-70b-8192`
- **Max Tokens**: 1000
- **Temperature**: 0.8 (for creative content generation)
- **System Prompt**: Optimized for social media content creation

### Fallback AI Service: Anthropic Claude
- **Model**: `claude-3-sonnet-20240229`
- **Max Tokens**: 1000
- **API Version**: `2023-06-01`

### Template Fallback System
If both AI services fail, the system uses intelligent templates based on content type detection:

#### Content Types Supported:
1. **Promotional Content**: For sales, offers, and promotions
2. **Educational Content**: For tips, tutorials, and learning content
3. **Engagement Content**: For questions, polls, and community engagement
4. **Announcement Content**: For news, updates, and announcements
5. **General Content**: Default template for other content types

## Sample Generated Content Examples

### Promotional Content Example
```
🚀 Exciting news! Special 50% off sale this weekend!

Don't miss out on this amazing opportunity! 

✨ Why choose us?
• Quality you can trust
• Exceptional customer service
• Competitive pricing

Ready to get started? Click the link in our bio or DM us for more info! 💬

#Marketing #Business #Quality #CustomerFirst #ExcitingNews
```

### Educational Content Example
```
💡 Pro Tip: How to increase your social media engagement

Here's what you need to know:

📚 Key takeaways:
• Stay informed and updated
• Apply these insights to your strategy
• Share your experience with others

What's your experience with this? Let us know in the comments! 👇

#Education #ProTips #Learning #Growth #Knowledge
```

## Rate Limiting and Usage Tracking

### Current Implementation
- Token usage estimation: ~4 characters per token
- Daily credit tracking per user
- Usage logging for analytics and billing

### Future Enhancements
- Implement database table for `ContentGenerationLog`
- Add subscription-based credit system
- Rate limiting based on user tier
- Advanced analytics dashboard

## Security Features
- JWT token authentication required
- User authentication validation
- Request parameter validation
- Comprehensive error handling
- Secure API key management

## Performance Considerations
- 30-second timeout for AI API calls
- Graceful fallback to template system
- Efficient token estimation
- Comprehensive logging for monitoring

## Backend Implementation Details

### Service Class: `ContentAiService`
- Located: `app/services/content_ai_service.rb`
- Handles AI API integration and template fallbacks
- Optimized prompts for social media content

### Controller: `ContentGenerationController`
- Located: `app/controllers/api/v1/content_generation_controller.rb`
- Handles authentication, validation, and response formatting
- Comprehensive error handling and logging

### Route Configuration
```ruby
# config/routes.rb
post 'generate-content', to: 'content_generation#create'
```

## Testing the API

### Using cURL
```bash
curl -X POST https://api.marketincer.com/api/v1/generate-content \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"description": "generate note on social media"}'
```

### Using Postman
1. Set method to POST
2. URL: `https://api.marketincer.com/api/v1/generate-content`
3. Headers:
   - `Authorization: Bearer YOUR_JWT_TOKEN`
   - `Content-Type: application/json`
4. Body (raw JSON):
   ```json
   {
     "description": "generate note on social media"
   }
   ```

## Environment Variables Required
```bash
# Required for Anthropic API (optional fallback)
ANTHROPIC_API_KEY=your_anthropic_api_key_here

# Groq API key is hardcoded in the service (consider moving to ENV)
# GROQ_API_KEY=your_groq_api_key_here
```

## Monitoring and Logging
- All requests are logged with user ID and description
- AI API responses and errors are logged
- Token usage tracking for billing purposes
- Performance metrics for response times

This API provides a robust, scalable solution for AI-powered social media content generation with comprehensive error handling, multiple AI service fallbacks, and intelligent template systems.