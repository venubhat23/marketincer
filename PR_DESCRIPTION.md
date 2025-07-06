# Instagram Analytics API Implementation

## Summary
This PR introduces a comprehensive Instagram Analytics API that provides detailed analytics for Instagram Business accounts connected to the platform. The API offers structured endpoints for retrieving profile data, media analytics, and engagement metrics.

## What's New

### 🆕 New Files Added
- `app/services/instagram_analytics_service.rb` - Service class for Instagram Basic Display API integration
- `app/controllers/api/v1/instagram_analytics_controller.rb` - Controller with 6 comprehensive endpoints
- `INSTAGRAM_ANALYTICS_API.md` - Complete API documentation with examples

### 🔧 Modified Files
- `config/routes.rb` - Added new routes for Instagram Analytics API

## API Endpoints

### 1. **GET** `/api/v1/instagram_analytics`
- **Purpose**: Get analytics for all connected Instagram pages
- **Response**: Array of page analytics with profile, media, and engagement data

### 2. **GET** `/api/v1/instagram_analytics/:page_id`
- **Purpose**: Get comprehensive analytics for a specific Instagram page
- **Response**: Complete analytics including profile, media, and summary data

### 3. **GET** `/api/v1/instagram_analytics/:page_id/profile`
- **Purpose**: Get profile data only (followers, bio, etc.)
- **Response**: Instagram profile information

### 4. **GET** `/api/v1/instagram_analytics/:page_id/media`
- **Purpose**: Get media posts with optional limit parameter
- **Response**: Array of media posts with engagement data

### 5. **GET** `/api/v1/instagram_analytics/:page_id/analytics`
- **Purpose**: Get analytics calculations only
- **Response**: Engagement stats, posting frequency, top posts

### 6. **GET** `/api/v1/instagram_analytics/:page_id/media/:media_id`
- **Purpose**: Get detailed information for specific media
- **Response**: Complete media details with engagement metrics

## Key Features

### 📊 Analytics Capabilities
- **Profile Analytics**: Followers, following, bio, engagement rate
- **Media Analytics**: Posts, media types, engagement per post
- **Content Analysis**: Posting frequency, top performing content
- **Engagement Metrics**: Likes, comments, shares, total engagement
- **Performance Insights**: Average engagement, best content types

### 🔒 Security & Error Handling
- User authentication required for all endpoints
- Proper authorization checks (users can only access their own data)
- Comprehensive error handling with meaningful messages
- Graceful handling of missing data and API failures
- Returns empty JSON objects when no data is available

### 🎯 Response Structure
- Consistent JSON response format across all endpoints
- Clear success/failure indicators
- Detailed error messages for debugging
- Structured data objects for easy frontend integration

## Technical Implementation

### Service Layer (`InstagramAnalyticsService`)
- Handles all Instagram Basic Display API calls
- Implements proper error handling and logging
- Provides methods for:
  - Profile data retrieval
  - Media data fetching
  - Analytics calculations
  - Content analysis

### Controller Layer (`InstagramAnalyticsController`)
- RESTful API design with clear endpoints
- Proper HTTP status codes
- Authentication and authorization
- Structured JSON responses
- Parameter validation

## Usage Example

```bash
# Get all Instagram analytics for authenticated user
curl -X GET "https://your-domain.com/api/v1/instagram_analytics" \
  -H "Authorization: Bearer YOUR_TOKEN"

# Get specific page analytics
curl -X GET "https://your-domain.com/api/v1/instagram_analytics/17841473301334161" \
  -H "Authorization: Bearer YOUR_TOKEN"

# Get only profile data
curl -X GET "https://your-domain.com/api/v1/instagram_analytics/17841473301334161/profile" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Data Sources
- Instagram Basic Display API
- Existing `SocialPage` and `SocialAccount` models
- Facebook Graph API v18.0

## Requirements
- Instagram Business Account
- Valid access token with Instagram Basic Display permissions
- Connected social page in the system (page_type: 'instagram')

## Benefits
- **Clean API Structure**: Modular endpoints for specific data needs
- **Comprehensive Analytics**: Complete Instagram performance metrics
- **Developer Friendly**: Clear documentation and consistent responses
- **Scalable**: Service-based architecture for easy maintenance
- **Error Resilient**: Proper error handling and graceful degradation

## Testing
- API endpoints follow RESTful conventions
- Error scenarios are handled appropriately
- Authentication and authorization are properly implemented
- Data validation ensures clean responses

## Documentation
Complete API documentation is available in `INSTAGRAM_ANALYTICS_API.md` with:
- Detailed endpoint descriptions
- Request/response examples
- Error handling scenarios
- Data structure references

## Migration Notes
- This is a new API and doesn't affect existing functionality
- Existing influencer analytics API remains unchanged
- No database migrations required
- Uses existing model relationships

---

**Ready for Review**: This PR is ready for code review and testing. The API provides a solid foundation for Instagram analytics with room for future enhancements.