#!/bin/bash

# Test script for Enhanced Shortlink API
# Make sure to replace YOUR_TOKEN with a valid JWT token

BASE_URL="https://api.marketincer.com/api/v1"
TOKEN="YOUR_TOKEN"

echo "=== Testing Enhanced Shortlink API ==="
echo

# Test 1: Basic short link
echo "1. Creating basic short link..."
curl -X POST "$BASE_URL/short_links" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "destination_url": "https://example.com"
  }' | jq .
echo -e "\n"

# Test 2: Advanced short link with custom back-half
echo "2. Creating short link with custom back-half..."
curl -X POST "$BASE_URL/short_links" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "destination_url": "https://example.com/products",
    "title": "Product Page",
    "custom_back_half": "products-2025"
  }' | jq .
echo -e "\n"

# Test 3: Short link with UTM parameters
echo "3. Creating short link with UTM parameters..."
curl -X POST "$BASE_URL/short_links" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "destination_url": "https://example.com/campaign",
    "title": "Marketing Campaign",
    "enable_utm": true,
    "utm_source": "newsletter",
    "utm_medium": "email",
    "utm_campaign": "spring_sale",
    "utm_term": "discount",
    "utm_content": "header_link"
  }' | jq .
echo -e "\n"

# Test 4: Full-featured short link with QR code
echo "4. Creating full-featured short link with QR code..."
curl -X POST "$BASE_URL/short_links" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "destination_url": "https://example.com/special-offer",
    "title": "Special Offer",
    "custom_back_half": "special-2025",
    "enable_utm": true,
    "utm_source": "qr_code",
    "utm_medium": "print",
    "utm_campaign": "offline_promo",
    "enable_qr": true
  }' | jq .
echo -e "\n"

# Test 5: Try duplicate custom back-half (should fail)
echo "5. Testing duplicate custom back-half (should return 409)..."
curl -X POST "$BASE_URL/short_links" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "destination_url": "https://example.com/duplicate",
    "custom_back_half": "special-2025"
  }' | jq .
echo -e "\n"

# Test 6: Get QR code (if QR was enabled in previous test)
echo "6. Getting QR code for 'special-2025'..."
curl -X GET "$BASE_URL/short_links/special-2025/qr" \
  -H "Authorization: Bearer $TOKEN" \
  --output test_qr.png
echo "QR code saved as test_qr.png"
echo -e "\n"

# Test 7: Test redirection (this will follow the redirect)
echo "7. Testing redirection for 'special-2025'..."
curl -I "https://api.marketincer.com/r/special-2025"
echo -e "\n"

echo "=== Tests completed ==="
echo "Note: Replace YOUR_TOKEN with a valid JWT token before running this script"