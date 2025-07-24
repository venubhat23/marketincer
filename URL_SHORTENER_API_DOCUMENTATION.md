# 🔗 URL Shortener API Documentation

A comprehensive Bitly-like URL shortening service with advanced analytics, user management, and click tracking.

## 📋 Table of Contents

- [Authentication](#authentication)
- [API Endpoints](#api-endpoints)
  - [Create Short URL](#1-create-short-url)
  - [Get User URLs](#2-get-user-urls)
  - [Get Single URL Details](#3-get-single-url-details)
  - [Update Short URL](#4-update-short-url)
  - [Delete/Deactivate URL](#5-delete-deactivate-url)
  - [User Dashboard](#6-user-dashboard)
  - [URL Analytics](#7-url-analytics)
  - [Analytics Summary](#8-analytics-summary)
  - [Export Analytics](#9-export-analytics)
  - [URL Redirection](#10-url-redirection)
  - [URL Preview](#11-url-preview)
  - [URL Info](#12-url-info)
- [Error Handling](#error-handling)
- [Rate Limiting](#rate-limiting)
- [Examples](#examples)

---

## 🔐 Authentication

All API endpoints (except redirection) require JWT authentication via the `Authorization` header:

```http
Authorization: Bearer <jwt_token>
```

**Example:**
```bash
curl -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9..." \
     https://api.example.com/api/v1/shorten
```

---

## 🚀 API Endpoints

### 1. Create Short URL

**POST** `/api/v1/shorten`

Create a new shortened URL.

#### 📥 Request Body

```json
{
  "short_url": {
    "long_url": "https://example.com/very-long-url-path",
    "title": "My Website",
    "description": "This is my awesome website"
  }
}
```

#### 📤 Response (201 Created)

```json
{
  "short_url": "https://app.marketincer.com/r/abc123",
  "long_url": "https://example.com/very-long-url-path",
  "short_code": "abc123",
  "clicks": 0,
  "message": "URL shortened successfully",
  "created_at": "2025-07-22T14:00:00Z"
}
```

#### ❌ Error Response (422 Unprocessable Entity)

```json
{
  "errors": ["Long url must be a valid URL"],
  "message": "Failed to shorten URL"
}
```

---

### 2. Get User URLs

**GET** `/api/v1/users/{user_id}/urls`

Retrieve all URLs created by a specific user with pagination.

#### 📋 Query Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `page` | integer | 1 | Page number for pagination |

#### 📤 Response (200 OK)

```json
{
  "user_id": 123,
  "total_links": 15,
  "total_clicks": 1250,
  "page": 1,
  "per_page": 20,
  "urls": [
    {
      "id": 1,
      "long_url": "https://example.com/page1",
      "short_url": "https://app.marketincer.com/r/abc123",
      "short_code": "abc123",
      "clicks": 45,
      "title": "Example Page 1",
      "description": "First example page",
      "active": true,
      "created_at": "2025-07-22T10:00:00Z"
    },
    {
      "id": 2,
      "long_url": "https://example.com/page2",
      "short_url": "https://app.marketincer.com/r/def456",
      "short_code": "def456",
      "clicks": 23,
      "title": "Example Page 2",
      "description": "Second example page",
      "active": true,
      "created_at": "2025-07-21T16:30:00Z"
    }
  ]
}
```

---

### 3. Get Single URL Details

**GET** `/api/v1/short_urls/{id}`

Get detailed information about a specific short URL including basic analytics.

#### 📤 Response (200 OK)

```json
{
  "id": 1,
  "long_url": "https://example.com/page1",
  "short_url": "https://app.marketincer.com/r/abc123",
  "short_code": "abc123",
  "clicks": 45,
  "title": "Example Page 1",
  "description": "First example page",
  "active": true,
  "created_at": "2025-07-22T10:00:00Z",
  "analytics": {
    "clicks_today": 5,
    "clicks_this_week": 12,
    "clicks_this_month": 45,
    "clicks_by_country": {
      "USA": 20,
      "India": 15,
      "Germany": 10
    },
    "clicks_by_device": {
      "Mobile": 25,
      "Desktop": 15,
      "Tablet": 5
    },
    "clicks_by_browser": {
      "Chrome": 30,
      "Safari": 10,
      "Firefox": 5
    }
  }
}
```

---

### 4. Update Short URL

**PUT** `/api/v1/short_urls/{id}`

Update the title, description, or active status of a short URL.

#### 📥 Request Body

```json
{
  "short_url": {
    "title": "Updated Title",
    "description": "Updated description",
    "active": true
  }
}
```

#### 📤 Response (200 OK)

```json
{
  "id": 1,
  "long_url": "https://example.com/page1",
  "short_url": "https://app.marketincer.com/r/abc123",
  "short_code": "abc123",
  "clicks": 45,
  "title": "Updated Title",
  "description": "Updated description",
  "active": true,
  "message": "Short URL updated successfully",
  "updated_at": "2025-07-22T15:00:00Z"
}
```

---

### 5. Delete/Deactivate URL

**DELETE** `/api/v1/short_urls/{id}`

Deactivate a short URL (soft delete).

#### 📤 Response (200 OK)

```json
{
  "message": "Short URL deactivated successfully"
}
```

---

### 6. User Dashboard

**GET** `/api/v1/users/{user_id}/dashboard`

Get user dashboard with summary statistics and recent activity.

#### 📤 Response (200 OK)

```json
{
  "user_id": 123,
  "total_urls": 15,
  "total_clicks": 1250,
  "urls_created_this_month": 8,
  "recent_urls": [
    {
      "id": 1,
      "long_url": "https://example.com/recent1",
      "short_url": "https://app.marketincer.com/r/xyz789",
      "clicks": 12,
      "created_at": "2025-07-22T14:00:00Z"
    }
  ],
  "top_performing_urls": [
    {
      "id": 2,
      "long_url": "https://example.com/popular",
      "short_url": "https://app.marketincer.com/r/pop123",
      "clicks": 150,
      "created_at": "2025-07-20T10:00:00Z"
    }
  ]
}
```

---

### 7. URL Analytics

**GET** `/api/v1/analytics/{short_code}`

Get detailed analytics for a specific short URL.

#### 📤 Response (200 OK)

```json
{
  "short_code": "abc123",
  "short_url": "https://app.marketincer.com/r/abc123",
  "long_url": "https://example.com/page1",
  "title": "Example Page 1",
  "description": "First example page",
  "total_clicks": 45,
  "created_at": "2025-07-22T10:00:00Z",
  "clicks_by_day": {
    "2025-07-20": 5,
    "2025-07-21": 10,
    "2025-07-22": 20,
    "2025-07-23": 10
  },
  "clicks_by_country": {
    "USA": 20,
    "India": 15,
    "Germany": 10
  },
  "clicks_by_device": {
    "Mobile": 25,
    "Desktop": 15,
    "Tablet": 5
  },
  "clicks_by_browser": {
    "Chrome": 30,
    "Safari": 10,
    "Firefox": 5
  },
  "recent_clicks": [
    {
      "id": 1,
      "country": "USA",
      "city": "New York",
      "device_type": "Mobile",
      "browser": "Chrome",
      "os": "iOS",
      "referrer": "https://google.com",
      "ip_address": "192.168.1.xxx",
      "created_at": "2025-07-22T14:30:00Z"
    }
  ],
  "performance_metrics": {
    "clicks_today": 5,
    "clicks_this_week": 12,
    "clicks_this_month": 45,
    "average_clicks_per_day": 3.2,
    "peak_day": {
      "date": "2025-07-22",
      "clicks": 20
    },
    "conversion_rate": 8.5
  }
}
```

---

### 8. Analytics Summary

**GET** `/api/v1/analytics/summary`

Get aggregated analytics for all user's URLs.

#### 📤 Response (200 OK)

```json
{
  "user_id": 123,
  "total_urls": 15,
  "total_clicks": 1250,
  "average_clicks_per_url": 83.33,
  "top_performing_urls": [
    {
      "short_code": "top123",
      "short_url": "https://app.marketincer.com/r/top123",
      "long_url": "https://example.com/popular",
      "clicks": 200,
      "created_at": "2025-07-20T10:00:00Z"
    }
  ],
  "clicks_over_time": {
    "2025-07-20": 50,
    "2025-07-21": 75,
    "2025-07-22": 100
  },
  "device_breakdown": {
    "Mobile": 650,
    "Desktop": 400,
    "Tablet": 200
  },
  "country_breakdown": {
    "USA": 500,
    "India": 300,
    "Germany": 200,
    "Canada": 150,
    "UK": 100
  },
  "browser_breakdown": {
    "Chrome": 800,
    "Safari": 250,
    "Firefox": 150,
    "Edge": 50
  }
}
```

---

### 9. Export Analytics

**GET** `/api/v1/analytics/{short_code}/export`

Export detailed analytics data as CSV file.

#### 📤 Response (200 OK)

Returns a CSV file with headers:
- Date, Time, Country, City, Device, Browser, OS, Referrer, IP Address

---

### 10. URL Redirection

**GET** `/r/{short_code}`

Redirect to the original URL and track the click.

#### 📤 Response (301 Moved Permanently)

Redirects to the original URL and increments click counter.

#### ❌ Error Response (404 Not Found)

```json
{
  "error": "Short URL not found or inactive",
  "message": "The requested short URL does not exist or has been deactivated"
}
```

---

### 11. URL Preview

**GET** `/r/{short_code}/preview`

Preview URL information without redirecting.

#### 📤 Response (200 OK)

```json
{
  "short_code": "abc123",
  "short_url": "https://app.marketincer.com/r/abc123",
  "long_url": "https://example.com/page1",
  "title": "Example Page 1",
  "description": "This link will redirect you to: https://example.com/page1",
  "clicks": 45,
  "created_at": "2025-07-22T10:00:00Z",
  "warning": "You are about to be redirected to an external website. Please verify the URL is safe before proceeding."
}
```

---

### 12. URL Info

**GET** `/r/{short_code}/info`

Get public information about a short URL including QR code.

#### 📤 Response (200 OK)

```json
{
  "short_code": "abc123",
  "short_url": "https://app.marketincer.com/r/abc123",
  "long_url": "https://example.com/page1",
  "title": "Example Page 1",
  "description": "First example page",
  "clicks": 45,
  "created_at": "2025-07-22T10:00:00Z",
  "qr_code_url": "https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=https%3A//app.marketincer.com/r/abc123"
}
```

---

## ❌ Error Handling

### Standard Error Response Format

```json
{
  "error": "Error type",
  "message": "Detailed error message",
  "errors": ["Array of specific validation errors"]
}
```

### HTTP Status Codes

| Code | Description |
|------|-------------|
| `200` | Success |
| `201` | Created |
| `301` | Moved Permanently (redirects) |
| `400` | Bad Request |
| `401` | Unauthorized |
| `403` | Forbidden |
| `404` | Not Found |
| `422` | Unprocessable Entity |
| `429` | Too Many Requests |
| `500` | Internal Server Error |

---

## 🛡️ Rate Limiting

- **URL Creation**: 100 URLs per hour per user
- **Analytics Requests**: 1000 requests per hour per user
- **Redirections**: No limit (public access)

Rate limit headers are included in responses:
```http
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1642694400
```

---

## 💡 Examples

### Creating a Short URL with cURL

```bash
curl -X POST https://api.example.com/api/v1/shorten \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "short_url": {
      "long_url": "https://example.com/very-long-url",
      "title": "My Example Page",
      "description": "This is an example page"
    }
  }'
```

### Getting User URLs with JavaScript

```javascript
const response = await fetch('https://api.example.com/api/v1/users/123/urls', {
  headers: {
    'Authorization': 'Bearer YOUR_JWT_TOKEN',
    'Content-Type': 'application/json'
  }
});

const data = await response.json();
console.log(data.urls);
```

### Redirecting Users

Simply visit the short URL in a browser:
```
https://app.marketincer.com/r/abc123
```

Or programmatically:
```javascript
window.location.href = 'https://app.marketincer.com/r/abc123';
```

---

## 🔧 Additional Features

### QR Code Generation
Each short URL automatically generates a QR code accessible via the info endpoint.

### Click Analytics
Detailed tracking including:
- Geographic location (country/city)
- Device type (Mobile/Desktop/Tablet)
- Browser and OS information
- Referrer tracking
- Time-based analytics

### Export Capabilities
Analytics data can be exported as CSV for further analysis.

### URL Preview
Safety feature allowing users to preview destination before redirecting.

---

## 📞 Support

For API support, please contact:
- **Email**: api-support@example.com
- **Documentation**: https://docs.example.com/url-shortener
- **Status Page**: https://status.example.com

---

**Last Updated**: July 22, 2025
**API Version**: v1.0.0