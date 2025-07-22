# 🚀 URL Shortener Quick Setup Guide

## 📋 Prerequisites

- Ruby 3.3.7+
- Rails 8.0.1+
- PostgreSQL with JSON support
- Bundler installed

## ⚡ Quick Start

### 1. Install Dependencies
```bash
bundle install
```

### 2. Database Setup
The database tables are already created. Verify with:
```bash
bundle exec rails runner "puts ShortUrl.table_exists? ? '✅ Ready!' : '❌ Run migrations'"
```

### 3. Test the Implementation
```bash
bundle exec rails runner "
# Create a test user (if needed)
user = User.first || User.create!(
  email: 'test@example.com', 
  password: 'password123',
  activated: true
)

# Create a short URL
short_url = user.short_urls.create!(
  long_url: 'https://example.com/test-page',
  title: 'Test Page'
)

puts '🔗 Short URL created:'
puts '   Long URL: ' + short_url.long_url
puts '   Short URL: ' + short_url.short_url
puts '   Short Code: ' + short_url.short_code
puts '   User: ' + user.email
"
```

### 4. Start the Server
```bash
bundle exec rails server
```

## 🧪 Test the API

### Create a JWT Token (for testing)
```bash
bundle exec rails runner "
user = User.first
token = JWT.encode({ user_id: user.id }, Rails.application.secret_key_base, 'HS256')
puts '🔑 JWT Token:'
puts token
"
```

### Test URL Creation
```bash
# Replace YOUR_JWT_TOKEN with the token from above
curl -X POST http://localhost:3000/api/v1/shorten \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "short_url": {
      "long_url": "https://google.com",
      "title": "Google Search"
    }
  }'
```

### Test URL Redirection
```bash
# Visit the short URL (replace abc123 with actual short code)
curl -L http://localhost:3000/r/abc123
```

### Test Analytics
```bash
# Get analytics for a short code
curl -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  http://localhost:3000/api/v1/analytics/abc123
```

## 📊 Available Endpoints

### Core API Endpoints
- `POST /api/v1/shorten` - Create short URL
- `GET /api/v1/users/:user_id/urls` - List user URLs
- `GET /api/v1/users/:user_id/dashboard` - User dashboard
- `GET /api/v1/short_urls/:id` - Get URL details
- `PUT /api/v1/short_urls/:id` - Update URL
- `DELETE /api/v1/short_urls/:id` - Delete URL

### Analytics Endpoints
- `GET /api/v1/analytics/summary` - Analytics summary
- `GET /api/v1/analytics/:short_code` - Detailed analytics
- `GET /api/v1/analytics/:short_code/export` - Export CSV

### Public Endpoints (No Auth Required)
- `GET /r/:short_code` - Redirect to original URL
- `GET /r/:short_code/preview` - Preview URL info
- `GET /r/:short_code/info` - Get URL info + QR code

## 🔧 Configuration

### Environment Variables (Optional)
```bash
# JWT Secret (defaults to Rails.application.secret_key_base)
export JWT_SECRET=your_jwt_secret

# Database URL (if not using default Rails config)
export DATABASE_URL=postgresql://user:pass@localhost/dbname
```

### CORS Configuration
The system uses the existing CORS configuration. Make sure your frontend domain is allowed in the CORS settings.

## 📚 Documentation

- **Full API Documentation**: `URL_SHORTENER_API_DOCUMENTATION.md`
- **Implementation Details**: `URL_SHORTENER_IMPLEMENTATION_SUMMARY.md`

## 🐛 Troubleshooting

### Common Issues

**1. Models not found**
```bash
# Restart Rails console/server after adding new models
bundle exec rails runner "puts ShortUrl.name"
```

**2. Database tables missing**
```bash
# Check if tables exist
bundle exec rails runner "
puts 'short_urls: ' + ActiveRecord::Base.connection.table_exists?('short_urls').to_s
puts 'click_analytics: ' + ActiveRecord::Base.connection.table_exists?('click_analytics').to_s
"
```

**3. Authentication errors**
- Make sure to include `Authorization: Bearer <token>` header
- Verify JWT token is valid and not expired
- Check user exists in database

**4. CORS errors**
- Verify frontend domain is allowed in CORS configuration
- Include proper headers in requests

## 🎯 Next Steps

1. **Frontend Integration**: Use the API endpoints in your frontend application
2. **Authentication**: Integrate with your existing user authentication system
3. **Analytics**: Set up dashboards using the analytics endpoints
4. **Monitoring**: Monitor API usage and performance
5. **Scaling**: Consider caching and CDN for high-traffic scenarios

## 📞 Support

- Check the comprehensive API documentation
- Review the implementation summary for technical details
- Test individual endpoints using curl or Postman
- Verify database setup and model loading

---

**Ready to go!** 🚀 Your URL shortener is now fully functional with all features implemented.