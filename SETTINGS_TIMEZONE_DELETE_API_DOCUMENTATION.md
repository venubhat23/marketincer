# Settings API - Timezone & Delete Account Documentation

## Overview
This document covers the new timezone management and account deletion endpoints added to the Settings API.

## Authentication
All endpoints require authentication using JWT token in the Authorization header:
```
Authorization: Bearer <jwt_token>
```

## Base URL
```
/api/v1/settings
```

## New Endpoints

### 1. GET /api/v1/settings/timezones
Get list of available timezones for dropdown selection.

**Headers:**
```
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

**Response (200 OK):**
```json
{
  "status": "success",
  "data": [
    {
      "value": "Asia/Kolkata",
      "label": "India Standard Time (IST)",
      "offset": "+05:30"
    },
    {
      "value": "America/New_York",
      "label": "Eastern Time (ET)",
      "offset": "-05:00"
    },
    {
      "value": "America/Los_Angeles",
      "label": "Pacific Time (PT)",
      "offset": "-08:00"
    },
    {
      "value": "Europe/London",
      "label": "Greenwich Mean Time (GMT)",
      "offset": "+00:00"
    },
    {
      "value": "Europe/Berlin",
      "label": "Central European Time (CET)",
      "offset": "+01:00"
    },
    {
      "value": "Asia/Tokyo",
      "label": "Japan Standard Time (JST)",
      "offset": "+09:00"
    },
    {
      "value": "Asia/Shanghai",
      "label": "China Standard Time (CST)",
      "offset": "+08:00"
    },
    {
      "value": "Australia/Sydney",
      "label": "Australian Eastern Time (AET)",
      "offset": "+10:00"
    },
    {
      "value": "Asia/Dubai",
      "label": "Gulf Standard Time (GST)",
      "offset": "+04:00"
    },
    {
      "value": "Asia/Singapore",
      "label": "Singapore Standard Time (SGT)",
      "offset": "+08:00"
    },
    {
      "value": "Europe/Paris",
      "label": "Central European Time (CET)",
      "offset": "+01:00"
    },
    {
      "value": "America/Chicago",
      "label": "Central Time (CT)",
      "offset": "-06:00"
    },
    {
      "value": "America/Denver",
      "label": "Mountain Time (MT)",
      "offset": "-07:00"
    },
    {
      "value": "Pacific/Auckland",
      "label": "New Zealand Standard Time (NZST)",
      "offset": "+12:00"
    },
    {
      "value": "Africa/Cairo",
      "label": "Eastern European Time (EET)",
      "offset": "+02:00"
    }
  ]
}
```

### 2. PATCH /api/v1/settings/timezone
Update user's timezone preference.

**Headers:**
```
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "timezone": "Asia/Kolkata"
}
```

**Response (200 OK):**
```json
{
  "status": "success",
  "message": "Timezone updated successfully",
  "data": {
    "timezone": "Asia/Kolkata"
  }
}
```

**Error Response (422 Unprocessable Entity):**
```json
{
  "status": "error",
  "message": "Failed to update timezone",
  "errors": [
    "Timezone is not a valid timezone"
  ]
}
```

### 3. DELETE /api/v1/settings/delete_account
Delete user account (soft delete - deactivates account).

**Headers:**
```
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "password": "user_current_password"
}
```

**Response (200 OK):**
```json
{
  "status": "success",
  "message": "Account deleted successfully"
}
```

**Error Response (401 Unauthorized):**
```json
{
  "status": "error",
  "message": "Password is incorrect"
}
```

**Error Response (422 Unprocessable Entity):**
```json
{
  "status": "error",
  "message": "Failed to delete account",
  "errors": [
    "Validation error details"
  ]
}
```

**Error Response (500 Internal Server Error):**
```json
{
  "status": "error",
  "message": "Failed to delete account",
  "errors": [
    "Server error details"
  ]
}
```

## Updated Endpoints

### GET /api/v1/settings
The main settings endpoint now includes timezone information in the response.

**Updated Response (200 OK):**
```json
{
  "status": "success",
  "data": {
    "personal_information": {
      "first_name": "Oliva",
      "last_name": "Rhye",
      "email": "oliva@untitledui.com",
      "phone_number": "+1 (555) 000-0000",
      "bio": "Digital marketing specialist with 5+ years of experience in growth strategies.",
      "avatar_url": "https://example.com/avatars/oliva.jpg",
      "timezone": "Asia/Kolkata"
    },
    "company_details": {
      "name": "Untitled UI",
      "gst_name": "Untitled UI Private Limited",
      "gst_number": "29ABCDE1234F1Z5",
      "phone_number": "+1 (555) 000-0000",
      "address": "123 Business Street, Tech City, TC 12345",
      "website": "https://www.untitledui.com"
    }
  }
}
```

### PATCH /api/v1/settings/personal_information
The personal information update endpoint now supports timezone updates and includes timezone in response.

**Updated Request Body:**
```json
{
  "personal_information": {
    "first_name": "Olivia",
    "last_name": "Rhye",
    "email": "olivia@untitledui.com",
    "phone_number": "+1 (555) 123-4567",
    "bio": "Senior Digital Marketing Specialist with expertise in growth hacking and data-driven strategies.",
    "avatar_url": "https://example.com/avatars/olivia.jpg",
    "timezone": "America/New_York"
  }
}
```

**Updated Response (200 OK):**
```json
{
  "status": "success",
  "message": "Personal information updated successfully",
  "data": {
    "first_name": "Olivia",
    "last_name": "Rhye",
    "email": "olivia@untitledui.com",
    "phone_number": "+1 (555) 123-4567",
    "bio": "Senior Digital Marketing Specialist with expertise in growth hacking and data-driven strategies.",
    "avatar_url": "https://example.com/avatars/olivia.jpg",
    "timezone": "America/New_York"
  }
}
```

## Testing with cURL

### Get Available Timezones
```bash
curl -X GET http://localhost:3000/api/v1/settings/timezones \
  -H "Authorization: Bearer <your_jwt_token>" \
  -H "Content-Type: application/json"
```

### Update Timezone
```bash
curl -X PATCH http://localhost:3000/api/v1/settings/timezone \
  -H "Authorization: Bearer <your_jwt_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "timezone": "Asia/Kolkata"
  }'
```

### Delete Account
```bash
curl -X DELETE http://localhost:3000/api/v1/settings/delete_account \
  -H "Authorization: Bearer <your_jwt_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "password": "user_current_password"
  }'
```

### Update Personal Information with Timezone
```bash
curl -X PATCH http://localhost:3000/api/v1/settings/personal_information \
  -H "Authorization: Bearer <your_jwt_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "personal_information": {
      "first_name": "Olivia",
      "last_name": "Rhye",
      "email": "olivia@untitledui.com",
      "phone_number": "+1 (555) 123-4567",
      "bio": "Senior Digital Marketing Specialist with expertise in growth hacking and data-driven strategies.",
      "timezone": "America/New_York"
    }
  }'
```

## Frontend Implementation Notes

### Timezone Dropdown
1. Fetch available timezones from `/api/v1/settings/timezones`
2. Display in a dropdown with label and offset information
3. Default to "Asia/Kolkata" for new users
4. Save selection via `/api/v1/settings/timezone` endpoint

### Delete Account
1. Show confirmation modal with password input
2. Require password confirmation for security
3. Display warning about data deletion
4. Redirect to login page after successful deletion
5. Handle error cases appropriately

## Database Changes

### Migration
A new migration has been created to add the timezone field:

```ruby
# db/migrate/20250122000001_add_timezone_to_users.rb
class AddTimezoneToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :timezone, :string, default: 'Asia/Kolkata'
  end
end
```

### User Model Validation
The User model now includes timezone validation:

```ruby
validates :timezone, presence: true, inclusion: { 
  in: ['Asia/Kolkata', 'America/New_York', 'America/Los_Angeles', 'Europe/London', 'Europe/Berlin', 
       'Asia/Tokyo', 'Asia/Shanghai', 'Australia/Sydney', 'Asia/Dubai', 'Asia/Singapore', 
       'Europe/Paris', 'America/Chicago', 'America/Denver', 'Pacific/Auckland', 'Africa/Cairo'],
  message: "is not a valid timezone" 
}
```

## Security Notes

1. **Delete Account**: Uses soft delete (deactivation) to preserve data integrity
2. **Password Verification**: Required for account deletion
3. **Timezone Validation**: Server-side validation ensures only valid timezones are accepted
4. **Authentication**: All endpoints require valid JWT token

## Error Handling

- **401 Unauthorized**: Invalid or missing JWT token, incorrect password
- **422 Unprocessable Entity**: Validation errors (invalid timezone, etc.)
- **500 Internal Server Error**: Server errors during account deletion

## Default Values

- **Timezone**: New users default to "Asia/Kolkata" (Indian Standard Time)
- **Account Status**: Deleted accounts are marked as `activated: false`