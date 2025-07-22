# Settings API Documentation

## Overview
The Settings API provides endpoints to manage user personal information, company details, and password changes.

## Authentication
All endpoints require authentication using JWT token in the Authorization header:
```
Authorization: Bearer <jwt_token>
```

## Base URL
```
/api/v1/settings
```

## Endpoints

### 1. GET /api/v1/settings
Get all user settings including personal information and company details.

**Headers:**
```
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

**Response (200 OK):**
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

### 2. PATCH /api/v1/settings/personal_information
Update user's personal information.

**Headers:**
```
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "personal_information": {
    "first_name": "Olivia",
    "last_name": "Rhye",
    "email": "olivia@untitledui.com",
    "phone_number": "+1 (555) 123-4567",
    "bio": "Senior Digital Marketing Specialist with expertise in growth hacking and data-driven strategies.",
    "avatar_url": "https://example.com/avatars/olivia.jpg"
  }
}
```

**Response (200 OK):**
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
    "avatar_url": "https://example.com/avatars/olivia.jpg"
  }
}
```

**Error Response (422 Unprocessable Entity):**
```json
{
  "status": "error",
  "message": "Failed to update personal information",
  "errors": [
    "Email has already been taken",
    "Phone number is invalid"
  ]
}
```

### 3. PATCH /api/v1/settings/company_details
Update user's company details.

**Headers:**
```
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "company_details": {
    "company_name": "Untitled UI Inc",
    "gst_name": "Untitled UI Incorporated",
    "gst_number": "29ABCDE1234F1Z6",
    "company_phone": "+1 (555) 000-1000",
    "company_address": "456 Innovation Drive, Tech Hub, TH 54321",
    "company_website": "https://www.untitledui.com"
  }
}
```

**Response (200 OK):**
```json
{
  "status": "success",
  "message": "Company details updated successfully",
  "data": {
    "name": "Untitled UI Inc",
    "gst_name": "Untitled UI Incorporated",
    "gst_number": "29ABCDE1234F1Z6",
    "phone_number": "+1 (555) 000-1000",
    "address": "456 Innovation Drive, Tech Hub, TH 54321",
    "website": "https://www.untitledui.com"
  }
}
```

### 4. GET /api/v1/settings/timezones
Get available timezones for dropdown selection.

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
      "value": "Europe/London",
      "label": "Greenwich Mean Time (GMT)",
      "offset": "+00:00"
    }
  ]
}
```

### 5. PATCH /api/v1/settings/timezone
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

### 6. DELETE /api/v1/settings/delete_account
Delete user account (soft delete).

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

### 7. PATCH /api/v1/settings/change_password
Change user's password.

**Headers:**
```
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "current_password": "oldpassword123",
  "new_password": "newpassword456",
  "confirm_password": "newpassword456"
}
```

**Response (200 OK):**
```json
{
  "status": "success",
  "message": "Password updated successfully"
}
```

**Error Response (401 Unauthorized):**
```json
{
  "status": "error",
  "message": "Current password is incorrect"
}
```

**Error Response (422 Unprocessable Entity):**
```json
{
  "status": "error",
  "message": "Failed to update password",
  "errors": [
    "Password confirmation doesn't match Password",
    "Password is too short (minimum is 6 characters)"
  ]
}
```

## Testing with cURL

### Get Settings
```bash
curl -X GET http://localhost:3000/api/v1/settings \
  -H "Authorization: Bearer <your_jwt_token>" \
  -H "Content-Type: application/json"
```

### Update Personal Information
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
      "bio": "Senior Digital Marketing Specialist with expertise in growth hacking and data-driven strategies."
    }
  }'
```

### Update Company Details
```bash
curl -X PATCH http://localhost:3000/api/v1/settings/company_details \
  -H "Authorization: Bearer <your_jwt_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "company_details": {
      "company_name": "Untitled UI Inc",
      "gst_name": "Untitled UI Incorporated",
      "gst_number": "29ABCDE1234F1Z6",
      "company_phone": "+1 (555) 000-1000",
      "company_address": "456 Innovation Drive, Tech Hub, TH 54321",
      "company_website": "https://www.untitledui.com"
    }
  }'
```

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

### Change Password
```bash
curl -X PATCH http://localhost:3000/api/v1/settings/change_password \
  -H "Authorization: Bearer <your_jwt_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "current_password": "oldpassword123",
    "new_password": "newpassword456",
    "confirm_password": "newpassword456"
  }'
```

## Database Migration

To add the required fields to the users table, run:
```bash
rails db:migrate
```

This will add the following columns to the users table:
- `bio` (text)
- `avatar_url` (string)
- `company_name` (string)
- `timezone` (string, default: 'Asia/Kolkata')

## Sample Data

To create sample data for testing, run:
```bash
rails db:seed
```

This will create a sample user with email `oliva@untitledui.com` and password `password123`.

## Authentication

To get a JWT token for testing, first login using the existing login endpoint:

```bash
curl -X POST http://localhost:3000/api/v1/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "oliva@untitledui.com",
    "password": "password123"
  }'
```

Use the returned token in the Authorization header for all Settings API requests.