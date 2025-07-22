# 📘 Instagram Influencer Discovery API Documentation

A powerful, AI-enhanced discovery system to find **top Instagram influencers** via smart filtering and optional **username-based search**.

## 🚀 API Overview

**Base URL:** `https://your-domain.com/api/v1`  
**Endpoint:** `POST /instagram/discover`  
**Authentication:** ❌ **None Required** (Public API)  
**Content-Type:** `application/json`

---

## 📋 Request Format

### HTTP Method
```
POST /api/v1/instagram/discover
```

### Request Headers
```
Content-Type: application/json
```

### Request Body Structure
```json
{
  "filters": {
    "username_search": "string (optional)",
    "type": "string (optional)",
    "size": "string (optional)",
    "gender": "string (optional)",
    "location": "string (optional)",
    "country": "string (optional)",
    "categories": ["array of strings (optional)"],
    "audience_filters": {
      "age_range_min": "integer (optional)",
      "age_range_max": "integer (optional)",
      "gender": "string (optional)",
      "location": "string (optional)",
      "quality_score_min": "integer (optional)",
      "interests": ["array of strings (optional)"]
    },
    "performance_filters": {
      "engagement_rate_min": "float (optional)",
      "avg_views_min": "integer (optional)",
      "follower_growth_min": "float (optional)",
      "comment_rate_min": "float (optional)"
    }
  },
  "limit": "integer (optional, default: 20, max: 100)",
  "sort_by": "string (optional, default: 'followers')"
}
```

---

## 🔧 Filter Parameters

### 🔹 Influencer Filters

| Parameter | Type | Values | Description |
|-----------|------|--------|-------------|
| `username_search` | `string` | Any username/name | **Priority search** - finds influencers matching this name |
| `type` | `string` | `Creator`, `Business`, `Personal` | Instagram account type |
| `size` | `string` | `nano`, `micro`, `macro`, `mega` | Follower count categories |
| `gender` | `string` | `Male`, `Female`, `Other` | Influencer gender |
| `location` | `string` | Any location | Influencer's residence/location |
| `country` | `string` | Any country | Alternative to location |
| `categories` | `array` | `["Fashion", "Travel", "Food", "Tech", "Sports", ...]` | Content niches |

### 🔹 Audience Filters

| Parameter | Type | Values | Description |
|-----------|------|--------|-------------|
| `age_range_min` | `integer` | 13-65 | Minimum audience age |
| `age_range_max` | `integer` | 13-65 | Maximum audience age |
| `gender` | `string` | `Male`, `Female`, `Mixed` | Audience gender distribution |
| `location` | `string` | Any location | Target audience region |
| `quality_score_min` | `integer` | 0-100 | Minimum audience quality score |
| `interests` | `array` | `["Fashion", "Fitness", ...]` | Audience interests |

### 🔹 Performance Filters

| Parameter | Type | Values | Description |
|-----------|------|--------|-------------|
| `engagement_rate_min` | `float` | 0.0-20.0 | Minimum engagement rate (%) |
| `avg_views_min` | `integer` | Any number | Minimum average views per post |
| `follower_growth_min` | `float` | 0.0-100.0 | Minimum monthly growth rate (%) |
| `comment_rate_min` | `float` | 0.0-10.0 | Minimum comment rate (%) |

### 🔹 General Parameters

| Parameter | Type | Values | Description |
|-----------|------|--------|-------------|
| `limit` | `integer` | 1-100 | Number of results to return (default: 20) |
| `sort_by` | `string` | `followers`, `engagement`, `quality_score` | Sorting criteria |

---

## 📊 Influencer Size Categories

| Size | Follower Range |
|------|----------------|
| `nano` | 0 - 10K |
| `micro` | 10K - 100K |
| `macro` | 100K - 1M |
| `mega` | 1M+ |

---

## 📝 Example Requests

### 1. 🔍 **Username Search (Priority)**
Search for influencers named "Virat":

```bash
curl -X POST "https://your-domain.com/api/v1/instagram/discover" \
  -H "Content-Type: application/json" \
  -d '{
    "filters": {
      "username_search": "Virat"
    },
    "limit": 10,
    "sort_by": "followers"
  }'
```

### 2. 🎯 **Comprehensive Filtering**
Find female fashion micro-influencers in India:

```bash
curl -X POST "https://your-domain.com/api/v1/instagram/discover" \
  -H "Content-Type: application/json" \
  -d '{
    "filters": {
      "type": "Creator",
      "size": "micro",
      "gender": "Female",
      "location": "India",
      "categories": ["Fashion", "Beauty"],
      "audience_filters": {
        "age_range_min": 18,
        "age_range_max": 35,
        "gender": "Female",
        "location": "India",
        "quality_score_min": 75,
        "interests": ["Fashion", "Beauty", "Lifestyle"]
      },
      "performance_filters": {
        "engagement_rate_min": 3.0
      }
    },
    "limit": 25,
    "sort_by": "engagement"
  }'
```

### 3. 🏃‍♂️ **Sports Influencers**
Find sports mega-influencers with high engagement:

```bash
curl -X POST "https://your-domain.com/api/v1/instagram/discover" \
  -H "Content-Type: application/json" \
  -d '{
    "filters": {
      "size": "mega",
      "categories": ["Sports", "Fitness"],
      "performance_filters": {
        "engagement_rate_min": 2.5,
        "avg_views_min": 500000
      }
    },
    "limit": 15,
    "sort_by": "followers"
  }'
```

### 4. 🌍 **Global Tech Influencers**
Find technology influencers with quality audience:

```bash
curl -X POST "https://your-domain.com/api/v1/instagram/discover" \
  -H "Content-Type: application/json" \
  -d '{
    "filters": {
      "categories": ["Tech", "Technology"],
      "audience_filters": {
        "age_range_min": 25,
        "age_range_max": 45,
        "quality_score_min": 80,
        "interests": ["Technology", "Gadgets", "Innovation"]
      }
    },
    "limit": 20,
    "sort_by": "quality_score"
  }'
```

---

## 📤 Response Format

### ✅ **Success Response**
```json
{
  "success": true,
  "message": "Influencers discovered successfully",
  "total_results": 3,
  "limit": 20,
  "sort_by": "followers",
  "filters_applied": {
    "username_search": "Virat",
    "categories": ["Sports"]
  },
  "results": [
    {
      "username": "@virat.kohli",
      "followers": 265000000,
      "location": "India",
      "category": "Sports",
      "engagement_rate": 2.8,
      "audience": {
        "age_range": "18-34",
        "gender": "Mixed",
        "location": "India",
        "interests": ["Cricket", "Fitness"],
        "quality_score": 91
      },
      "recent_posts": [
        "https://instagram.com/p/virat_post1",
        "https://instagram.com/p/virat_post2"
      ]
    },
    {
      "username": "@viratk_fitness",
      "followers": 120000,
      "location": "Delhi",
      "category": "Fitness",
      "engagement_rate": 6.1,
      "audience": {
        "age_range": "18-24",
        "gender": "Male",
        "location": "India",
        "interests": ["Fitness"],
        "quality_score": 85
      },
      "recent_posts": [
        "https://instagram.com/p/fitness_post1"
      ]
    }
  ],
  "search_metadata": {
    "search_time": 2.34,
    "ai_provider": "groq",
    "query_complexity": "medium"
  }
}
```

### ❌ **Error Responses**

#### Missing Filters
```json
{
  "success": false,
  "error": "Missing required parameter: filters",
  "message": "Please provide filters for influencer discovery"
}
```

#### Limit Too High
```json
{
  "success": false,
  "error": "Limit too high",
  "message": "Maximum limit is 100 influencers per request"
}
```

#### Internal Server Error
```json
{
  "success": false,
  "error": "Internal server error",
  "message": "An unexpected error occurred while discovering influencers"
}
```

---

## 🎯 Search Priority Logic

When `username_search` is provided:

1. **Exact username matches** are ranked highest
2. **Partial matches** in username or bio
3. **Other relevant influencers** based on filters
4. Results sorted by specified `sort_by` criteria

When `username_search` is NOT provided:
- Results ranked purely by `sort_by` criteria
- All filters applied equally

---

## 🤖 AI Integration

### Supported AI Providers
1. **Groq API** (Primary) - Ultra-fast inference
2. **OpenAI GPT-3.5** (Fallback) - High-quality responses
3. **Mock Data** (Final fallback) - Ensures API availability

### AI Response Quality
- **Query Complexity**: `low`, `medium`, `high`
- **Search Time**: Actual processing time in seconds
- **AI Provider**: Which AI service was used

---

## 📊 Response Data Structure

### Influencer Object
```json
{
  "username": "@example_user",           // Instagram handle
  "followers": 150000,                   // Follower count
  "location": "India",                   // Influencer location
  "category": "Fashion",                 // Primary content category
  "engagement_rate": 4.2,               // Engagement percentage
  "audience": {
    "age_range": "18-34",               // Primary audience age
    "gender": "Mixed",                   // Audience gender split
    "location": "India",                 // Audience geography
    "interests": ["Fashion", "Beauty"],  // Audience interests
    "quality_score": 85                  // Audience quality (0-100)
  },
  "recent_posts": [                      // Recent post URLs
    "https://instagram.com/p/example1",
    "https://instagram.com/p/example2"
  ]
}
```

---

## 🚦 Rate Limits

- **No authentication required**
- **No rate limits** currently enforced
- Maximum **100 influencers** per request
- Recommended: **20-50 influencers** for optimal performance

---

## 🔧 HTTP Status Codes

| Status | Description |
|--------|-------------|
| `200` | Success - Influencers found |
| `400` | Bad Request - Invalid parameters |
| `422` | Unprocessable Entity - Discovery failed |
| `500` | Internal Server Error - Unexpected error |

---

## 🌟 Best Practices

### 1. **Optimize Your Searches**
- Use specific `categories` for better results
- Combine multiple filters for precision
- Use `username_search` for finding specific influencers

### 2. **Performance Tips**
- Start with `limit: 20` for faster responses
- Use `sort_by` strategically based on your needs
- Combine audience and performance filters

### 3. **Error Handling**
- Always check the `success` field
- Handle different error types appropriately
- Implement retry logic for network issues

### 4. **Data Usage**
- Cache results when possible
- Use `search_metadata` for analytics
- Monitor `query_complexity` for optimization

---

## 🔗 Integration Examples

### JavaScript/Node.js
```javascript
const discoverInfluencers = async (filters) => {
  const response = await fetch('https://your-domain.com/api/v1/instagram/discover', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      filters: filters,
      limit: 20,
      sort_by: 'followers'
    })
  });
  
  const data = await response.json();
  
  if (data.success) {
    return data.results;
  } else {
    throw new Error(data.message);
  }
};

// Usage
const influencers = await discoverInfluencers({
  username_search: "Virat",
  categories: ["Sports"]
});
```

### Python
```python
import requests

def discover_influencers(filters, limit=20, sort_by='followers'):
    url = 'https://your-domain.com/api/v1/instagram/discover'
    payload = {
        'filters': filters,
        'limit': limit,
        'sort_by': sort_by
    }
    
    response = requests.post(url, json=payload)
    data = response.json()
    
    if data['success']:
        return data['results']
    else:
        raise Exception(data['message'])

# Usage
influencers = discover_influencers({
    'username_search': 'Virat',
    'categories': ['Sports']
})
```

### cURL
```bash
#!/bin/bash

# Function to discover influencers
discover_influencers() {
  curl -X POST "https://your-domain.com/api/v1/instagram/discover" \
    -H "Content-Type: application/json" \
    -d "$1" | jq '.'
}

# Example usage
FILTERS='{
  "filters": {
    "username_search": "Virat",
    "categories": ["Sports"]
  },
  "limit": 10
}'

discover_influencers "$FILTERS"
```

---

## 🎯 Use Cases

### 1. **Brand Partnerships**
Find influencers matching your target demographic and engagement requirements.

### 2. **Competitor Analysis**
Discover influencers working with competitors in your industry.

### 3. **Market Research**
Analyze influencer landscapes across different categories and regions.

### 4. **Campaign Planning**
Build influencer lists for upcoming marketing campaigns.

---

## 🔍 Troubleshooting

### Common Issues

1. **Empty Results**
   - Try broader filters
   - Check spelling in `username_search`
   - Reduce `performance_filters` requirements

2. **Slow Responses**
   - Reduce `limit` parameter
   - Simplify filter combinations
   - Monitor `query_complexity`

3. **Inconsistent Results**
   - AI responses may vary slightly
   - Use caching for consistent user experience
   - Implement result deduplication if needed

---

## 📞 Support

For technical support or feature requests, please contact:
- **Email**: api-support@your-domain.com
- **Documentation**: https://docs.your-domain.com
- **Status Page**: https://status.your-domain.com

---

**Last Updated**: January 2024  
**API Version**: 1.0  
**Documentation Version**: 1.0