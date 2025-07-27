# Enhanced URL Shortener API

## Overview

The enhanced URL shortener API provides advanced features including:
- Custom back-half URLs
- UTM parameter handling
- QR code generation
- Comprehensive metadata storage

## API Endpoints

### 1. Create Enhanced Short Link

**POST** `/api/v1/short_links`

Create a short link with advanced features.

#### Request Body

```json
{
  "destination_url": "https://example.com/my-long-url",
  "title": "Optional title for link",
  "custom_back_half": "my-custom-code",
  "enable_utm": true,
  "utm_source": "google",
  "utm_medium": "cpc",
  "utm_campaign": "spring_sale",
  "utm_term": "running+shoes",
  "utm_content": "logolink",
  "enable_qr": true
}
```

#### Response (201 Created)

```json
{
  "short_link": "https://api.marketincer.com/r/my-custom-code",
  "original_url": "https://example.com/my-long-url",
  "final_url": "https://example.com/my-long-url?utm_source=google&utm_medium=cpc&utm_campaign=spring_sale&utm_term=running+shoes&utm_content=logolink",
  "title": "Optional title for link",
  "custom_back_half": "my-custom-code",
  "enable_utm": true,
  "utm_params": {
    "source": "google",
    "medium": "cpc",
    "campaign": "spring_sale",
    "term": "running+shoes",
    "content": "logolink"
  },
  "enable_qr": true,
  "qr_code_url": "https://api.marketincer.com/qr/my-custom-code.png",
  "created_at": "2025-01-27T10:00:00Z"
}
```

#### Error Responses

**409 Conflict** - Custom code already exists
```json
{
  "error": "The custom back-half 'my-custom-code' is already taken."
}
```

**400 Bad Request** - Invalid data
```json
{
  "error": "Destination URL is required."
}
```

### 2. Get QR Code

**GET** `/api/v1/short_links/:code/qr`

Returns the QR code image for a short link.

#### Response
- Content-Type: `image/png`
- Returns PNG image data

#### Error Responses

**404 Not Found** - QR code not enabled or not found
```json
{
  "error": "QR code not enabled for this link"
}
```

### 3. URL Redirection

**GET** `/r/:code`

Redirects to the final URL (with UTM parameters if enabled).

- Returns HTTP 301 redirect to `final_url`
- Tracks click analytics
- Increments click counter

## Field Descriptions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `destination_url` | string | Yes | The original URL to shorten |
| `title` | string | No | Optional title for the link |
| `custom_back_half` | string | No | Custom short code (3-50 chars, must be unique) |
| `enable_utm` | boolean | No | Enable UTM parameter tracking |
| `utm_source` | string | No | UTM source parameter |
| `utm_medium` | string | No | UTM medium parameter |
| `utm_campaign` | string | No | UTM campaign parameter |
| `utm_term` | string | No | UTM term parameter |
| `utm_content` | string | No | UTM content parameter |
| `enable_qr` | boolean | No | Enable QR code generation |

## Business Logic

1. **Custom Code Validation**: If provided, custom back-half must be unique
2. **UTM Parameter Handling**: When enabled, UTM parameters are appended to the destination URL to create the final URL
3. **QR Code Generation**: When enabled, generates a PNG QR code image stored in `/public/qr/`
4. **URL Redirection**: Uses `final_url` for redirection to include UTM parameters
5. **Analytics Tracking**: All clicks are tracked with detailed analytics

## Usage Examples

### Basic Short Link
```bash
curl -X POST https://api.marketincer.com/api/v1/short_links \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "destination_url": "https://example.com"
  }'
```

### Advanced Short Link with UTM and QR
```bash
curl -X POST https://api.marketincer.com/api/v1/short_links \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "destination_url": "https://example.com/products",
    "title": "Product Launch",
    "custom_back_half": "launch2025",
    "enable_utm": true,
    "utm_source": "newsletter",
    "utm_medium": "email",
    "utm_campaign": "july_launch",
    "enable_qr": true
  }'
```

### Get QR Code
```bash
curl https://api.marketincer.com/api/v1/short_links/launch2025/qr \
  -H "Authorization: Bearer YOUR_TOKEN" \
  --output qr_code.png
```

## Migration Required

Run the following migration to add the new database columns:

```bash
rails db:migrate
```

This will add the following columns to the `short_urls` table:
- `custom_back_half` (string)
- `enable_utm` (boolean, default: false)
- `utm_source`, `utm_medium`, `utm_campaign`, `utm_term`, `utm_content` (string)
- `enable_qr` (boolean, default: false)
- `qr_code_url` (string)
- `final_url` (text)

## Dependencies

Add to your Gemfile:
```ruby
gem 'rqrcode'      # For QR code generation
gem 'chunky_png'   # For PNG image generation
```

Then run:
```bash
bundle install
```