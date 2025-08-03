# User API Documentation

This document provides comprehensive information about the User API endpoints including timezone management, user profile updates, and account deletion functionality.

## Base URL
```
https://api.marketincer.com/api/v1
```

## Authentication
All endpoints require authentication using Bearer token in the Authorization header:
```
Authorization: Bearer <your_token>
```

---

## 1. Timezone Management APIs

### 1.1 Get Available Timezones
**Endpoint:** `GET /settings/timezones`

**Description:** Retrieves a list of all available timezones with their display names and offsets.

**Request:**
```bash
curl -X GET "https://api.marketincer.com/api/v1/settings/timezones" \
  -H "Authorization: Bearer <your_token>" \
  -H "Content-Type: application/json"
```

**Response:**
```json
{
  "status": "success",
  "data": {
    "timezones": [
      {
        "name": "Asia/Kolkata",
        "display_name": "Asia/Kolkata (GMT+05:30)",
        "offset": "+05:30"
      },
      {
        "name": "America/New_York",
        "display_name": "America/New_York (GMT-05:00)",
        "offset": "-05:00"
      },
      {
        "name": "Europe/London",
        "display_name": "Europe/London (GMT+00:00)",
        "offset": "+00:00"
      }
      // ... more timezones
    ],
    "current_timezone": "Asia/Kolkata"
  }
}
```

### 1.2 Update User Timezone
**Endpoint:** `PATCH /settings/timezone`

**Description:** Updates the user's timezone setting.

**Request:**
```bash
curl -X PATCH "https://api.marketincer.com/api/v1/settings/timezone" \
  -H "Authorization: Bearer <your_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "timezone": "America/New_York"
  }'
```

**Response:**
```json
{
  "status": "success",
  "message": "Timezone updated successfully",
  "data": {
    "timezone": "America/New_York"
  }
}
```

**Error Response:**
```json
{
  "status": "error",
  "message": "Failed to update timezone",
  "errors": ["Timezone is not a valid timezone"]
}
```

---

## 2. User Profile Management APIs

### 2.1 Get All User Settings
**Endpoint:** `GET /settings`

**Description:** Retrieves all user settings including personal information, company details, and timezone.

**Request:**
```bash
curl -X GET "https://api.marketincer.com/api/v1/settings" \
  -H "Authorization: Bearer <your_token>" \
  -H "Content-Type: application/json"
```

**Response:**
```json
{
  "status": "success",
  "data": {
    "personal_information": {
      "first_name": "John",
      "last_name": "Doe",
      "email": "john.doe@example.com",
      "phone_number": "+1234567890",
      "bio": "Marketing professional",
      "avatar_url": "https://example.com/avatar.jpg"
    },
    "company_details": {
      "name": "Tech Corp",
      "gst_name": "Tech Corp Private Limited",
      "gst_number": "22AAAAA0000A1Z5",
      "phone_number": "+1234567890",
      "address": "123 Tech Street, Silicon Valley",
      "website": "https://techcorp.com"
    },
    "timezone": "Asia/Kolkata"
  }
}
```

### 2.2 Update Personal Information
**Endpoint:** `PATCH /settings/personal_information`

**Description:** Updates user's personal information.

**Request:**
```bash
curl -X PATCH "https://api.marketincer.com/api/v1/settings/personal_information" \
  -H "Authorization: Bearer <your_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "personal_information": {
      "first_name": "Jane",
      "last_name": "Smith",
      "email": "jane.smith@example.com",
      "phone_number": "+1987654321",
      "bio": "Digital marketing expert",
      "avatar_url": "https://example.com/new-avatar.jpg"
    }
  }'
```

**Response:**
```json
{
  "status": "success",
  "message": "Personal information updated successfully",
  "data": {
    "first_name": "Jane",
    "last_name": "Smith",
    "email": "jane.smith@example.com",
    "phone_number": "+1987654321",
    "bio": "Digital marketing expert",
    "avatar_url": "https://example.com/new-avatar.jpg"
  }
}
```

### 2.3 Update Company Details
**Endpoint:** `PATCH /settings/company_details`

**Description:** Updates user's company information.

**Request:**
```bash
curl -X PATCH "https://api.marketincer.com/api/v1/settings/company_details" \
  -H "Authorization: Bearer <your_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "company_details": {
      "company_name": "New Tech Corp",
      "gst_name": "New Tech Corp Private Limited",
      "gst_number": "22BBBBB0000B1Z5",
      "company_phone": "+1555666777",
      "company_address": "456 Innovation Drive, Tech City",
      "company_website": "https://newtechcorp.com"
    }
  }'
```

**Response:**
```json
{
  "status": "success",
  "message": "Company details updated successfully",
  "data": {
    "name": "New Tech Corp",
    "gst_name": "New Tech Corp Private Limited",
    "gst_number": "22BBBBB0000B1Z5",
    "phone_number": "+1555666777",
    "address": "456 Innovation Drive, Tech City",
    "website": "https://newtechcorp.com"
  }
}
```

### 2.4 Update User Profile (Alternative Endpoint)
**Endpoint:** `PUT /user/update_profile`

**Description:** Alternative endpoint for updating user profile information.

**Request:**
```bash
curl -X PUT "https://api.marketincer.com/api/v1/user/update_profile" \
  -H "Authorization: Bearer <your_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "first_name": "Updated",
      "last_name": "Name",
      "gst_name": "Updated Company",
      "gst_number": "22CCCCC0000C1Z5",
      "phone_number": "+1111222333",
      "address": "789 Updated Street",
      "company_website": "https://updated.com",
      "job_title": "Senior Manager",
      "work_email": "work@updated.com",
      "gst_percentage": 18.0
    }
  }'
```

**Response:**
```json
{
  "message": "Profile updated successfully",
  "user": {
    "id": 1,
    "first_name": "Updated",
    "last_name": "Name",
    "email": "user@example.com",
    // ... other user fields
  }
}
```

---

## 3. Password Management API

### 3.1 Change Password
**Endpoint:** `PATCH /settings/change_password`

**Description:** Changes the user's password after verifying the current password.

**Request:**
```bash
curl -X PATCH "https://api.marketincer.com/api/v1/settings/change_password" \
  -H "Authorization: Bearer <your_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "current_password": "oldpassword",
    "new_password": "newpassword123",
    "confirm_password": "newpassword123"
  }'
```

**Response:**
```json
{
  "status": "success",
  "message": "Password updated successfully"
}
```

**Error Responses:**
```json
// Wrong current password
{
  "status": "error",
  "message": "Current password is incorrect"
}

// Password confirmation mismatch
{
  "status": "error",
  "message": "Failed to update password",
  "errors": ["Password confirmation doesn't match Password"]
}

// Password too short
{
  "status": "error",
  "message": "Failed to update password",
  "errors": ["Password is too short (minimum is 6 characters)"]
}
```

---

## 4. Account Deletion API

### 4.1 Delete User Account
**Endpoint:** `DELETE /settings/delete_account`

**Description:** Permanently deletes the user account after password verification. This action cannot be undone.

**⚠️ WARNING:** This operation permanently deletes:
- User profile and personal information
- All marketplace posts
- All bids
- All short URLs and analytics
- All associated data

**Request:**
```bash
curl -X DELETE "https://api.marketincer.com/api/v1/settings/delete_account" \
  -H "Authorization: Bearer <your_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "password": "userpassword"
  }'
```

**Response:**
```json
{
  "status": "success",
  "message": "Account deleted successfully. We're sorry to see you go!",
  "data": {
    "deleted_user_email": "user@example.com",
    "deleted_at": "2024-01-15T10:30:45Z"
  }
}
```

**Error Responses:**
```json
// Wrong password
{
  "status": "error",
  "message": "Password is incorrect. Account deletion cancelled."
}

// Deletion failed
{
  "status": "error",
  "message": "Failed to delete account. Please try again or contact support.",
  "error": "Detailed error message"
}
```

---

## 5. Available Timezones

The system supports the following timezones:

| Timezone | Display Name | Offset |
|----------|--------------|--------|
| Asia/Kolkata | Asia/Kolkata (GMT+05:30) | +05:30 |
| America/New_York | America/New_York (GMT-05:00) | -05:00 |
| America/Los_Angeles | America/Los_Angeles (GMT-08:00) | -08:00 |
| Europe/London | Europe/London (GMT+00:00) | +00:00 |
| Europe/Berlin | Europe/Berlin (GMT+01:00) | +01:00 |
| Asia/Tokyo | Asia/Tokyo (GMT+09:00) | +09:00 |
| Asia/Shanghai | Asia/Shanghai (GMT+08:00) | +08:00 |
| Australia/Sydney | Australia/Sydney (GMT+10:00) | +10:00 |
| Asia/Dubai | Asia/Dubai (GMT+04:00) | +04:00 |
| Asia/Singapore | Asia/Singapore (GMT+08:00) | +08:00 |
| Europe/Paris | Europe/Paris (GMT+01:00) | +01:00 |
| America/Chicago | America/Chicago (GMT-06:00) | -06:00 |
| America/Denver | America/Denver (GMT-07:00) | -07:00 |
| Pacific/Auckland | Pacific/Auckland (GMT+12:00) | +12:00 |
| Africa/Cairo | Africa/Cairo (GMT+02:00) | +02:00 |

---

## 6. Error Handling

All endpoints follow a consistent error response format:

```json
{
  "status": "error",
  "message": "Error description",
  "errors": ["Detailed error 1", "Detailed error 2"]
}
```

### Common HTTP Status Codes:
- `200 OK` - Request successful
- `400 Bad Request` - Invalid request parameters
- `401 Unauthorized` - Authentication failed or missing
- `422 Unprocessable Entity` - Validation errors
- `500 Internal Server Error` - Server error

---

## 7. Rate Limiting

API requests are subject to rate limiting:
- **Standard endpoints**: 100 requests per minute per user
- **Account deletion**: 3 requests per hour per user (security measure)

---

## 8. Security Considerations

1. **Password Requirements**: Minimum 6 characters
2. **Account Deletion**: Requires password confirmation
3. **Timezone Validation**: Only predefined timezones are accepted
4. **Data Sanitization**: All input is validated and sanitized
5. **HTTPS Only**: All API calls must use HTTPS

---

## 9. Integration Examples

### JavaScript/Fetch Example:
```javascript
// Get available timezones
const getTimezones = async () => {
  const response = await fetch('/api/v1/settings/timezones', {
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    }
  });
  return await response.json();
};

// Update timezone
const updateTimezone = async (timezone) => {
  const response = await fetch('/api/v1/settings/timezone', {
    method: 'PATCH',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({ timezone })
  });
  return await response.json();
};

// Delete account (with confirmation)
const deleteAccount = async (password) => {
  if (confirm('Are you sure you want to delete your account? This cannot be undone.')) {
    const response = await fetch('/api/v1/settings/delete_account', {
      method: 'DELETE',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ password })
    });
    return await response.json();
  }
};
```

### Python/Requests Example:
```python
import requests

class UserAPI:
    def __init__(self, token, base_url="https://api.marketincer.com/api/v1"):
        self.token = token
        self.base_url = base_url
        self.headers = {
            'Authorization': f'Bearer {token}',
            'Content-Type': 'application/json'
        }
    
    def get_timezones(self):
        response = requests.get(f"{self.base_url}/settings/timezones", headers=self.headers)
        return response.json()
    
    def update_timezone(self, timezone):
        data = {'timezone': timezone}
        response = requests.patch(f"{self.base_url}/settings/timezone", 
                                json=data, headers=self.headers)
        return response.json()
    
    def delete_account(self, password):
        data = {'password': password}
        response = requests.delete(f"{self.base_url}/settings/delete_account", 
                                 json=data, headers=self.headers)
        return response.json()
```

---

## 10. Testing

You can test these endpoints using the provided test scripts in the repository:
- `test_settings_api.rb` - Ruby test script for settings endpoints
- Use Postman collection (if available) for interactive testing

---

This documentation covers the complete User API structure including timezone management, profile updates, and account deletion functionality. All endpoints are fully implemented and ready to use.