#!/bin/bash

# Test script for Content Generation API
# Usage: ./test_content_api.sh [TOKEN]

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
API_BASE_URL="http://localhost:3000/api/v1"
TOKEN=${1:-"your_test_jwt_token_here"}

echo -e "${BLUE}🚀 Content Generation API Test Suite${NC}"
echo "=================================================="
echo -e "Base URL: ${API_BASE_URL}"
echo -e "Token: ${TOKEN:0:20}..."
echo ""

# Test 1: Valid content generation request
echo -e "${YELLOW}📝 Test 1: Valid content generation request${NC}"
echo "Request: generate note on social media"

response=$(curl -s -w "\n%{http_code}" -X POST "${API_BASE_URL}/generate-content" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"description": "generate note on social media"}')

http_code=$(echo "$response" | tail -n1)
response_body=$(echo "$response" | head -n -1)

if [ "$http_code" = "200" ]; then
    echo -e "${GREEN}✅ Status: $http_code${NC}"
    echo -e "${GREEN}✅ Response received${NC}"
    # Pretty print JSON if jq is available
    if command -v jq &> /dev/null; then
        echo "$response_body" | jq '.'
    else
        echo "$response_body"
    fi
else
    echo -e "${RED}❌ Status: $http_code${NC}"
    echo "$response_body"
fi

echo ""

# Test 2: Missing description parameter
echo -e "${YELLOW}📝 Test 2: Missing description parameter${NC}"

response=$(curl -s -w "\n%{http_code}" -X POST "${API_BASE_URL}/generate-content" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{}')

http_code=$(echo "$response" | tail -n1)
response_body=$(echo "$response" | head -n -1)

if [ "$http_code" = "400" ]; then
    echo -e "${GREEN}✅ Status: $http_code (Expected 400)${NC}"
    if command -v jq &> /dev/null; then
        echo "$response_body" | jq '.'
    else
        echo "$response_body"
    fi
else
    echo -e "${RED}❌ Status: $http_code (Expected 400)${NC}"
    echo "$response_body"
fi

echo ""

# Test 3: Invalid token
echo -e "${YELLOW}📝 Test 3: Invalid authentication token${NC}"

response=$(curl -s -w "\n%{http_code}" -X POST "${API_BASE_URL}/generate-content" \
  -H "Authorization: Bearer invalid_token_123" \
  -H "Content-Type: application/json" \
  -d '{"description": "test content"}')

http_code=$(echo "$response" | tail -n1)
response_body=$(echo "$response" | head -n -1)

if [ "$http_code" = "401" ]; then
    echo -e "${GREEN}✅ Status: $http_code (Expected 401)${NC}"
    if command -v jq &> /dev/null; then
        echo "$response_body" | jq '.'
    else
        echo "$response_body"
    fi
else
    echo -e "${RED}❌ Status: $http_code (Expected 401)${NC}"
    echo "$response_body"
fi

echo ""

# Test 4: Different content types
echo -e "${YELLOW}📝 Test 4: Different content types${NC}"

test_cases=(
    "promote our new product launch"
    "how to increase social media engagement"
    "what's your favorite marketing strategy?"
    "announcing our new office location"
    "general social media post about our company"
)

for i in "${!test_cases[@]}"; do
    description="${test_cases[$i]}"
    echo -e "\n  Test 4.$((i+1)): ${description}"
    
    response=$(curl -s -w "\n%{http_code}" -X POST "${API_BASE_URL}/generate-content" \
      -H "Authorization: Bearer ${TOKEN}" \
      -H "Content-Type: application/json" \
      -d "{\"description\": \"${description}\"}")
    
    http_code=$(echo "$response" | tail -n1)
    response_body=$(echo "$response" | head -n -1)
    
    if [ "$http_code" = "200" ]; then
        echo -e "  ${GREEN}✅ Status: $http_code${NC}"
        if command -v jq &> /dev/null; then
            content_length=$(echo "$response_body" | jq -r '.content | length')
            echo -e "  ${GREEN}✅ Generated ${content_length} characters${NC}"
        else
            echo -e "  ${GREEN}✅ Content generated${NC}"
        fi
    else
        echo -e "  ${RED}❌ Status: $http_code${NC}"
    fi
done

echo ""
echo -e "${BLUE}✅ All tests completed!${NC}"
echo ""
echo -e "${YELLOW}Usage Notes:${NC}"
echo "- Replace 'your_test_jwt_token_here' with a valid JWT token"
echo "- Make sure your Rails server is running on localhost:3000"
echo "- Install 'jq' for better JSON formatting: brew install jq (macOS) or apt-get install jq (Ubuntu)"