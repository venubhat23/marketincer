#!/bin/bash

# Test script for AI Contract Generation API
# Make sure your Rails server is running on port 3000

echo "🚀 Testing AI Contract Generation API"
echo "=================================="

# Test 1: Simple AI Test (no database save)
echo ""
echo "📝 Test 1: Simple AI Service Test"
echo "--------------------------------"
curl -X POST http://localhost:3000/api/v1/contracts/test_ai \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Create a simple freelance web development contract for building an e-commerce website with payment terms and deliverables"
  }' | jq '.'

echo ""
echo "⏳ Waiting 2 seconds..."
sleep 2

# Test 2: Generate AI Contract (saves to database)
echo ""
echo "📝 Test 2: Generate AI Contract (with save)"
echo "-------------------------------------------"
curl -X POST http://localhost:3000/api/v1/contracts/generate \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Create an influencer collaboration agreement for Instagram posts about fitness products, including usage rights and payment terms",
    "save_contract": true
  }' | jq '.'

echo ""
echo "⏳ Waiting 2 seconds..."
sleep 2

# Test 3: Generate AI Contract (no save, just preview)
echo ""
echo "📝 Test 3: Generate AI Contract (preview only)"
echo "---------------------------------------------"
curl -X POST http://localhost:3000/api/v1/contracts/generate \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Create a basic NDA for a software development project with confidentiality clauses",
    "save_contract": false
  }' | jq '.'

echo ""
echo "⏳ Waiting 2 seconds..."
sleep 2

# Test 4: Check AI Generation Status
echo ""
echo "📊 Test 4: Check AI Generation Status"
echo "------------------------------------"
curl -X GET http://localhost:3000/api/v1/contracts/ai_status | jq '.'

echo ""
echo "✅ All tests completed!"
echo ""
echo "💡 Tips:"
echo "   - Make sure your Rails server is running: rails server"
echo "   - Check the Rails logs for detailed information"
echo "   - If you see 'command not found: jq', install it with: sudo apt-get install jq"
echo "   - Set up your API keys using the AI_SETUP_GUIDE.md"