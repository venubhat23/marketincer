# Instagram Analytics API Documentation

## Overview
The Instagram Analytics API provides comprehensive analytics data for Instagram Business accounts including profile information, media analytics, and engagement metrics.

## Base URL
```
/api/v1/instagram_analytics
```

## Authentication
All endpoints require user authentication. Include authentication headers with your requests.

## Endpoints

### 1. Get All Instagram Analytics
**GET** `/api/v1/instagram_analytics`

Returns analytics data for all Instagram pages connected to the authenticated user.

**Request:**
```bash
curl -X GET "https://your-domain.com/api/v1/instagram_analytics" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Response:**
```json
{
  "success": true,
  "message": "Instagram analytics retrieved successfully",
  "total_pages": 1,
  "data": [
    {
      "page_id": "17841473301334161",
      "page_name": "aksharshetty01012025",
      "username": "aksharshetty01012025",
      "social_id": "17841473301334161",
      "profile": {
        "id": "17841473301334161",
        "username": "aksharshetty01012025",
        "biography": "inteligent \nSmart \npower",
        "followers_count": 1,
        "follows_count": 0,
        "media_count": 1,
        "profile_picture_url": "https://scontent.fblr1-4.fna.fbcdn.net/...",
        "engagement_rate": 0.5
      },
      "analytics": {
        "total_posts": 1,
        "media_types": {"IMAGE": 1},
        "recent_posts": [...],
        "engagement_stats": {
          "total_likes": 0,
          "total_comments": 0,
          "total_engagement": 0,
          "average_likes_per_post": 0.0,
          "average_comments_per_post": 0.0,
          "average_engagement_per_post": 0.0
        },
        "top_performing_posts": [...]
      },
      "summary": {
        "total_posts": 1,
        "total_engagement": 0,
        "engagement_rate": "0.5%",
        "most_used_media_type": "IMAGE",
        "posting_frequency": "1 posts in 2025-07"
      },
      "collected_at": "2025-07-05T16:30:00Z"
    }
  ]
}
```

### 2. Get Single Instagram Analytics
**GET** `/api/v1/instagram_analytics/:page_id`

Returns comprehensive analytics for a specific Instagram page.

**Request:**
```bash
curl -X GET "https://your-domain.com/api/v1/instagram_analytics/17841473301334161" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Response:**
```json
{
  "success": true,
  "message": "Instagram analytics retrieved successfully",
  "page_info": {
    "page_id": "17841473301334161",
    "page_name": "aksharshetty01012025",
    "username": "aksharshetty01012025",
    "social_id": "17841473301334161"
  },
  "data": {
    "profile": {
      "id": "17841473301334161",
      "username": "aksharshetty01012025",
      "biography": "inteligent \nSmart \npower",
      "followers_count": 1,
      "follows_count": 0,
      "media_count": 1,
      "profile_picture_url": "https://scontent.fblr1-4.fna.fbcdn.net/...",
      "engagement_rate": 0.5
    },
    "analytics": {
      "total_posts": 1,
      "media_types": {"IMAGE": 1},
      "recent_posts": [
        {
          "id": "18046042016243689",
          "type": "IMAGE",
          "url": "https://www.instagram.com/p/DLtt1ulRKTs/",
          "media_url": "https://scontent.cdninstagram.com/...",
          "thumbnail_url": "https://scontent.cdninstagram.com/...",
          "caption": "aasvcxvc",
          "timestamp": "2025-07-05T05:26:27+0000",
          "likes": 0,
          "comments": 0,
          "engagement": 0
        }
      ],
      "posting_frequency": {"2025-07": 1},
      "engagement_stats": {
        "total_likes": 0,
        "total_comments": 0,
        "total_engagement": 0,
        "average_likes_per_post": 0.0,
        "average_comments_per_post": 0.0,
        "average_engagement_per_post": 0.0
      },
      "top_performing_posts": [...]
    },
    "summary": {
      "total_posts": 1,
      "total_engagement": 0,
      "engagement_rate": "0.5%",
      "most_used_media_type": "IMAGE",
      "posting_frequency": "1 posts in 2025-07"
    },
    "collected_at": "2025-07-05T16:30:00Z"
  }
}
```

### 3. Get Profile Data Only
**GET** `/api/v1/instagram_analytics/:page_id/profile`

Returns only the Instagram profile information.

**Request:**
```bash
curl -X GET "https://your-domain.com/api/v1/instagram_analytics/17841473301334161/profile" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Response:**
```json
{
  "success": true,
  "message": "Instagram profile retrieved successfully",
  "data": {
    "id": "17841473301334161",
    "username": "aksharshetty01012025",
    "media_count": 1,
    "biography": "inteligent \nSmart \npower",
    "followers_count": 1,
    "follows_count": 0,
    "profile_picture_url": "https://scontent.fblr1-4.fna.fbcdn.net/..."
  }
}
```

### 4. Get Media Data Only
**GET** `/api/v1/instagram_analytics/:page_id/media`

Returns media posts for the Instagram account.

**Query Parameters:**
- `limit` (optional): Number of media items to retrieve (default: 25)

**Request:**
```bash
curl -X GET "https://your-domain.com/api/v1/instagram_analytics/17841473301334161/media?limit=10" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Response:**
```json
{
  "success": true,
  "message": "Instagram media retrieved successfully",
  "total_media": 1,
  "data": {
    "data": [
      {
        "id": "18046042016243689",
        "media_type": "IMAGE",
        "media_url": "https://scontent.cdninstagram.com/...",
        "thumbnail_url": "https://scontent.cdninstagram.com/...",
        "permalink": "https://www.instagram.com/p/DLtt1ulRKTs/",
        "timestamp": "2025-07-05T05:26:27+0000",
        "caption": "aasvcxvc",
        "like_count": 0,
        "comments_count": 0
      }
    ],
    "paging": {
      "cursors": {
        "before": "QVFIUm4tVGZAhc...",
        "after": "QVFIUm4tVGZAhc..."
      }
    }
  }
}
```

### 5. Get Analytics Data Only
**GET** `/api/v1/instagram_analytics/:page_id/analytics`

Returns analytics calculations without profile data.

**Request:**
```bash
curl -X GET "https://your-domain.com/api/v1/instagram_analytics/17841473301334161/analytics" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Response:**
```json
{
  "success": true,
  "message": "Instagram analytics retrieved successfully",
  "data": {
    "total_posts": 1,
    "media_types": {"IMAGE": 1},
    "recent_posts": [...],
    "posting_frequency": {"2025-07": 1},
    "engagement_stats": {
      "total_likes": 0,
      "total_comments": 0,
      "total_engagement": 0,
      "average_likes_per_post": 0.0,
      "average_comments_per_post": 0.0,
      "average_engagement_per_post": 0.0
    },
    "top_performing_posts": [...]
  }
}
```

### 6. Get Media Details
**GET** `/api/v1/instagram_analytics/:page_id/media/:media_id`

Returns detailed information for a specific media item.

**Request:**
```bash
curl -X GET "https://your-domain.com/api/v1/instagram_analytics/17841473301334161/media/18046042016243689" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Response:**
```json
{
  "success": true,
  "message": "Media details retrieved successfully",
  "data": {
    "id": "18046042016243689",
    "media_type": "IMAGE",
    "media_url": "https://scontent.cdninstagram.com/...",
    "thumbnail_url": "https://scontent.cdninstagram.com/...",
    "permalink": "https://www.instagram.com/p/DLtt1ulRKTs/",
    "timestamp": "2025-07-05T05:26:27+0000",
    "caption": "aasvcxvc",
    "like_count": 0,
    "comments_count": 0,
    "username": "aksharshetty01012025"
  }
}
```

## Error Responses

### Page Not Found
```json
{
  "success": false,
  "message": "Instagram page not found",
  "data": {}
}
```

### No Access Token
```json
{
  "success": false,
  "message": "No access token found for this Instagram page",
  "data": {}
}
```

### API Error
```json
{
  "success": false,
  "message": "Failed to retrieve Instagram analytics",
  "error": "Detailed error message",
  "data": {}
}
```

### No Data Available
```json
{
  "success": false,
  "message": "No profile data found",
  "data": {}
}
```

## Rate Limiting
- Follow Instagram Basic Display API rate limits
- Requests are cached where possible to reduce API calls

## Requirements
- Instagram Business Account
- Valid access token with Instagram Basic Display permissions
- Connected social page in the system

## Data Structure Reference

### Profile Object
```json
{
  "id": "string",
  "username": "string",
  "biography": "string",
  "followers_count": "number",
  "follows_count": "number", 
  "media_count": "number",
  "profile_picture_url": "string",
  "engagement_rate": "number"
}
```

### Media Object
```json
{
  "id": "string",
  "media_type": "IMAGE|VIDEO|CAROUSEL_ALBUM",
  "media_url": "string",
  "thumbnail_url": "string",
  "permalink": "string",
  "timestamp": "string",
  "caption": "string",
  "like_count": "number",
  "comments_count": "number"
}
```

### Analytics Object
```json
{
  "total_posts": "number",
  "media_types": {"IMAGE": "number", "VIDEO": "number"},
  "recent_posts": ["array of media objects"],
  "posting_frequency": {"2025-07": "number"},
  "engagement_stats": {
    "total_likes": "number",
    "total_comments": "number",
    "total_engagement": "number",
    "average_likes_per_post": "number",
    "average_comments_per_post": "number",
    "average_engagement_per_post": "number"
  },
  "top_performing_posts": ["array of media objects"]
}
```