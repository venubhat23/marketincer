# 🛒 Marketplace API Documentation

This document provides comprehensive API documentation for the Marketplace feature that allows brands to create posts and influencers to bid on them.

## 🔐 Authentication

All endpoints require authentication via JWT token in the Authorization header:
```
Authorization: Bearer <your_jwt_token>
```

## 👥 User Roles

- **Admin/Brand** (`user.role == 'admin' or 'brand'`): Can create, manage marketplace posts, and view/manage bids
- **Influencer** (`user.role == 'influencer'`): Can view marketplace posts and submit bids

---

## 📝 Marketplace Posts Endpoints

### 1. Get Marketplace Feed (Influencers Only)
**GET** `/api/v1/marketplace_posts`

Returns published marketplace posts for influencers to browse.

**Query Parameters:**
- `category` (optional): Filter by category (`A` or `B`)
- `target_audience` (optional): Filter by target audience (`18–24`, `24–30`, `30–35`, `More than 35`)
- `page` (optional): Page number (default: 1)
- `per_page` (optional): Items per page (default: 10, max: 50)

**Response:**
```json
{
  "status": "success",
  "data": [
    {
      "id": 1,
      "title": "Fashion Brand Collaboration",
      "description": "Looking for fashion influencers to promote our new collection...",
      "brand_name": "Fashion Co.",
      "budget": 5000.00,
      "deadline": "2024-02-15",
      "location": "Mumbai",
      "platform": "Instagram",
      "category": "A",
      "target_audience": "24–30",
      "tags": ["Fashion", "Style"],
      "media_url": "https://example.com/image.jpg",
      "media_type": "image",
      "views_count": 125,
      "bids_count": 8,
      "created_at": "2024-01-15T10:30:00Z",
      "user_has_bid": false
    }
  ],
  "pagination": {
    "current_page": 1,
    "per_page": 10,
    "total_count": 25
  }
}
```

### 2. Get My Marketplace Posts (Brands/Admin Only)
**GET** `/api/v1/marketplace_posts/my_posts`

Returns the current user's marketplace posts.

**Response:**
```json
{
  "status": "success",
  "data": [
    {
      "id": 1,
      "title": "Fashion Brand Collaboration",
      "description": "Looking for fashion influencers...",
      "brand_name": "Fashion Co.",
      "budget": 5000.00,
      "deadline": "2024-02-15",
      "location": "Mumbai",
      "platform": "Instagram",
      "languages": "English, Hindi",
      "category": "A",
      "target_audience": "24–30",
      "tags": ["Fashion", "Style"],
      "media_url": "https://example.com/image.jpg",
      "media_type": "image",
      "status": "published",
      "views_count": 125,
      "bids_count": 8,
      "pending_bids_count": 5,
      "accepted_bids_count": 2,
      "rejected_bids_count": 1,
      "created_at": "2024-01-15T10:30:00Z",
      "updated_at": "2024-01-15T10:30:00Z"
    }
  ]
}
```

### 3. Get Single Marketplace Post
**GET** `/api/v1/marketplace_posts/:id`

Returns a single marketplace post. Increments view count for influencers.

**Response (Influencer):**
```json
{
  "status": "success",
  "data": {
    "id": 1,
    "title": "Fashion Brand Collaboration",
    "description": "Full description here...",
    "brand_name": "Fashion Co.",
    "budget": 5000.00,
    "deadline": "2024-02-15",
    "location": "Mumbai",
    "platform": "Instagram",
    "languages": "English, Hindi",
    "category": "A",
    "target_audience": "24–30",
    "tags": ["Fashion", "Style"],
    "media_url": "https://example.com/image.jpg",
    "media_type": "image",
    "views_count": 126,
    "bids_count": 8,
    "created_at": "2024-01-15T10:30:00Z",
    "user_has_bid": true,
    "user_bid": {
      "id": 15,
      "amount": 4500.00,
      "status": "pending",
      "created_at": "2024-01-16T09:15:00Z"
    }
  }
}
```

### 4. Create Marketplace Post (Brands/Admin Only)
**POST** `/api/v1/marketplace_posts`

Creates a new marketplace post.

**Request Body:**
```json
{
  "marketplace_post": {
    "title": "Fashion Brand Collaboration",
    "description": "Looking for fashion influencers to promote our new collection. Must have 10k+ followers.",
    "category": "A",
    "target_audience": "24–30",
    "budget": 5000.00,
    "location": "Mumbai",
    "platform": "Instagram",
    "languages": "English, Hindi",
    "deadline": "2024-02-15",
    "tags": "Fashion, Style, Trendy",
    "status": "published",
    "brand_name": "Fashion Co.",
    "media_url": "https://example.com/image.jpg",
    "media_type": "image"
  }
}
```

**Response:**
```json
{
  "status": "success",
  "message": "Marketplace post created successfully",
  "data": {
    // Same structure as get single post response for brands
  }
}
```

### 5. Update Marketplace Post (Brands/Admin Only)
**PUT** `/api/v1/marketplace_posts/:id`

Updates an existing marketplace post.

**Request Body:** Same as create request
**Response:** Same as create response

### 6. Delete Marketplace Post (Brands/Admin Only)
**DELETE** `/api/v1/marketplace_posts/:id`

Deletes a marketplace post.

**Response:**
```json
{
  "status": "success",
  "message": "Marketplace post deleted successfully"
}
```

### 7. Search Marketplace Posts (Influencers Only)
**GET** `/api/v1/marketplace_posts/search`

Search and filter marketplace posts.

**Query Parameters:**
- `q` (optional): Search query (searches title, description, tags, brand_name)
- `category` (optional): Filter by category
- `target_audience` (optional): Filter by target audience
- `budget_min` (optional): Minimum budget filter
- `budget_max` (optional): Maximum budget filter
- `deadline_from` (optional): Deadline from date (YYYY-MM-DD)
- `deadline_to` (optional): Deadline to date (YYYY-MM-DD)
- `location` (optional): Location filter
- `platform` (optional): Platform filter
- `page`, `per_page`: Pagination parameters

**Response:** Same structure as marketplace feed

### 8. Get Statistics
**GET** `/api/v1/marketplace_posts/statistics`

Returns role-based statistics.

**Response (Brand):**
```json
{
  "status": "success",
  "data": {
    "total_posts": 15,
    "published_posts": 12,
    "draft_posts": 3,
    "total_views": 1250,
    "total_bids": 45,
    "pending_bids": 20,
    "accepted_bids": 15,
    "rejected_bids": 10,
    "avg_bids_per_post": 3.75
  }
}
```

**Response (Influencer):**
```json
{
  "status": "success",
  "data": {
    "total_bids": 25,
    "pending_bids": 10,
    "accepted_bids": 8,
    "rejected_bids": 7,
    "total_bid_amount": 125000.00,
    "avg_bid_amount": 5000.00,
    "success_rate": 32.00
  }
}
```

### 9. Get Marketplace Insights (Admin Only)
**GET** `/api/v1/marketplace_posts/insights`

Returns overall marketplace insights.

**Response:**
```json
{
  "status": "success",
  "data": {
    "total_posts": 150,
    "total_bids": 450,
    "active_brands": 25,
    "active_influencers": 80,
    "avg_bids_per_post": 3.0,
    "categories": {
      "A": 85,
      "B": 65
    },
    "target_audiences": {
      "24–30": 60,
      "18–24": 45,
      "30–35": 30,
      "More than 35": 15
    }
  }
}
```

### 10. Get Recommended Posts (Influencers Only)
**GET** `/api/v1/marketplace_posts/recommended`

Returns recommended posts for the influencer (posts they haven't bid on).

**Query Parameters:**
- `limit` (optional): Number of recommendations (default: 10)

**Response:** Same structure as marketplace feed

---

## 🎯 Bids Endpoints

### 1. Get Bids for Marketplace Post (Brands/Admin Only)
**GET** `/api/v1/marketplace_posts/:marketplace_post_id/bids`

Returns all bids for a specific marketplace post.

**Response:**
```json
{
  "status": "success",
  "data": {
    "marketplace_post": {
      "id": 1,
      "title": "Fashion Brand Collaboration",
      "budget": 5000.00
    },
    "bids": [
      {
        "id": 15,
        "amount": 4500.00,
        "status": "pending",
        "message": "I have 15k followers and great engagement rates!",
        "influencer_name": "John Doe",
        "influencer_email": "john@example.com",
        "created_at": "2024-01-16T09:15:00Z",
        "updated_at": "2024-01-16T09:15:00Z"
      }
    ],
    "summary": {
      "total_bids": 8,
      "pending_bids": 5,
      "accepted_bids": 2,
      "rejected_bids": 1
    }
  }
}
```

### 2. Create Bid (Influencers Only)
**POST** `/api/v1/marketplace_posts/:marketplace_post_id/bids`

Creates a new bid for a marketplace post.

**Request Body:**
```json
{
  "bid": {
    "amount": 4500.00,
    "message": "I have 15k followers and great engagement rates! I'd love to work with your brand."
  }
}
```

**Response:**
```json
{
  "status": "success",
  "message": "Bid placed successfully",
  "data": {
    "id": 15,
    "amount": 4500.00,
    "status": "pending",
    "message": "I have 15k followers and great engagement rates!",
    "influencer_name": "John Doe",
    "influencer_email": "john@example.com",
    "created_at": "2024-01-16T09:15:00Z",
    "updated_at": "2024-01-16T09:15:00Z"
  }
}
```

### 3. Get Single Bid
**GET** `/api/v1/bids/:id`

Returns a single bid with detailed information.

**Response:**
```json
{
  "status": "success",
  "data": {
    "id": 15,
    "amount": 4500.00,
    "status": "pending",
    "message": "I have 15k followers and great engagement rates!",
    "influencer": {
      "id": 25,
      "name": "John Doe",
      "email": "john@example.com",
      "first_name": "John",
      "last_name": "Doe"
    },
    "marketplace_post": {
      "id": 1,
      "title": "Fashion Brand Collaboration",
      "budget": 5000.00,
      "brand_name": "Fashion Co."
    },
    "created_at": "2024-01-16T09:15:00Z",
    "updated_at": "2024-01-16T09:15:00Z"
  }
}
```

### 4. Update Bid (Influencers Only - Own Pending Bids)
**PUT** `/api/v1/bids/:id`

Updates a pending bid.

**Request Body:**
```json
{
  "bid": {
    "amount": 4000.00,
    "message": "Updated message with revised pricing."
  }
}
```

**Response:** Same as create bid response

### 5. Delete Bid (Influencers Only - Own Pending Bids)
**DELETE** `/api/v1/bids/:id`

Deletes a pending bid.

**Response:**
```json
{
  "status": "success",
  "message": "Bid deleted successfully"
}
```

### 6. Accept Bid (Brands/Admin Only)
**POST** `/api/v1/bids/:id/accept`

Accepts a bid.

**Response:**
```json
{
  "status": "success",
  "message": "Bid accepted successfully",
  "data": {
    // Bid data with status: "accepted"
  }
}
```

### 7. Reject Bid (Brands/Admin Only)
**POST** `/api/v1/bids/:id/reject`

Rejects a bid.

**Response:**
```json
{
  "status": "success",
  "message": "Bid rejected successfully",
  "data": {
    // Bid data with status: "rejected"
  }
}
```

### 8. Get My Bids (Influencers Only)
**GET** `/api/v1/bids/my_bids`

Returns all bids placed by the current influencer.

**Response:**
```json
{
  "status": "success",
  "data": [
    {
      "id": 15,
      "amount": 4500.00,
      "status": "pending",
      "message": "I have 15k followers and great engagement rates!",
      "marketplace_post": {
        "id": 1,
        "title": "Fashion Brand Collaboration",
        "brand_name": "Fashion Co.",
        "budget": 5000.00,
        "deadline": "2024-02-15",
        "status": "published"
      },
      "created_at": "2024-01-16T09:15:00Z",
      "updated_at": "2024-01-16T09:15:00Z"
    }
  ]
}
```

---

## 🔄 Status Values

### Marketplace Post Status:
- `draft`: Not visible to influencers
- `published`: Visible to influencers
- `archived`: No longer active

### Bid Status:
- `pending`: Waiting for brand decision
- `accepted`: Approved by brand
- `rejected`: Declined by brand

---

## 📊 Data Validation

### Marketplace Post Validation:
- `title`: Required, max 255 characters
- `description`: Required
- `budget`: Required, must be > 0
- `category`: Required, must be 'A' or 'B'
- `target_audience`: Required, must be one of: '18–24', '24–30', '30–35', 'More than 35'
- `deadline`: Required, must be in the future
- `location`: Required
- `platform`: Required
- `languages`: Required

### Bid Validation:
- `amount`: Required, must be > 0
- One bid per user per marketplace post
- Can only update/delete pending bids

---

## 🚫 Error Responses

All endpoints return consistent error responses:

```json
{
  "status": "error",
  "message": "Error description",
  "errors": ["Detailed error messages"]
}
```

Common HTTP status codes:
- `400` Bad Request: Invalid parameters
- `401` Unauthorized: Authentication required
- `403` Forbidden: Insufficient permissions
- `404` Not Found: Resource not found
- `422` Unprocessable Entity: Validation errors
- `500` Internal Server Error: Server error

---

## 🔐 Role-Based Access Control

| Endpoint | Admin | Brand | Influencer |
|----------|-------|-------|------------|
| GET marketplace_posts | ❌ | ❌ | ✅ |
| GET my_posts | ✅ | ✅ | ❌ |
| POST marketplace_posts | ✅ | ✅ | ❌ |
| PUT marketplace_posts | ✅ | ✅ (own) | ❌ |
| DELETE marketplace_posts | ✅ | ✅ (own) | ❌ |
| GET search | ❌ | ❌ | ✅ |
| GET insights | ✅ | ❌ | ❌ |
| POST bids | ❌ | ❌ | ✅ |
| GET bids (for post) | ✅ | ✅ (own posts) | ❌ |
| PUT bids | ❌ | ❌ | ✅ (own pending) |
| POST accept/reject | ✅ | ✅ (own posts) | ❌ |
| GET my_bids | ❌ | ❌ | ✅ |

---

## 📱 Frontend Integration Notes

1. **Role Detection**: Check `user.role` to show appropriate UI
2. **Real-time Updates**: Consider implementing WebSocket for bid notifications
3. **Image Upload**: Handle media uploads separately and pass URLs to API
4. **Pagination**: Implement infinite scroll or pagination controls
5. **Search/Filters**: Implement debounced search with filter combinations
6. **Bid Management**: Show bid status with appropriate actions
7. **Statistics Dashboard**: Use statistics endpoints for analytics views