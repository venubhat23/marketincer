# Enhanced AI Contract Generation - Testing Guide

## Overview

The AI contract generation system has been enhanced with ChatGPT-like natural language processing that automatically extracts entities from user input and generates personalized contracts.

## Key Features

### 1. Automatic Entity Extraction
The system now intelligently extracts:
- **Parties/Names**: Between X and Y, with X, etc.
- **Amounts**: Rs 5000, $1000, ₹50000, etc.
- **Dates**: Today, tomorrow, specific dates
- **Companies/Brands**: Nike, Google, Microsoft, etc.
- **Locations**: India, USA, Mumbai, Delhi, etc.
- **Contract Types**: Service, NDA, Collaboration, etc.
- **Durations**: 6 months, 1 year, etc.

### 2. Natural Language Processing
Users can now type naturally like:
```
"generate service agreement between nike and pramod on date of rs 5000"
"create collaboration agreement with john for $2000 effective today"
"draft nda between google and sarah for 6 months"
```

### 3. Intelligent Response
The system provides ChatGPT-like responses showing what it understood:
```json
{
  "success": true,
  "message": "Service Agreement generated successfully between Nike and Pramod, for 5000, effective today. I've automatically extracted and incorporated the key details from your request.",
  "contract_type": "Service Agreement",
  "extracted_entities": {
    "parties": ["Nike", "Pramod"],
    "amounts": ["5000"],
    "dates": ["December 17, 2024"],
    "companies": ["Nike"],
    "contract_types": ["Service Agreement"]
  }
}
```

## Test Examples

### Example 1: User's Original Request
```bash
curl -X POST https://api.marketincer.com/api/v1/contracts/generate \
  -H "Content-Type: application/json" \
  -d '{
    "description": "generate service agreement between nike and pramod on date of rs 5000",
    "save_contract": true
  }'
```

**Expected Response:**
- Extracts parties: Nike, Pramod
- Extracts amount: Rs 5000
- Extracts date: today's date
- Generates personalized Service Agreement
- Contract name: "Nike - Service Agreement - December 2024"

### Example 2: Collaboration Agreement
```bash
curl -X POST https://api.marketincer.com/api/v1/contracts/generate \
  -H "Content-Type: application/json" \
  -d '{
    "description": "collaboration agreement between google and sarah for $2000 effective tomorrow",
    "save_contract": true
  }'
```

**Expected Response:**
- Extracts parties: Google, Sarah
- Extracts amount: $2000
- Extracts date: tomorrow's date
- Generates Collaboration Agreement

### Example 3: NDA with Duration
```bash
curl -X POST https://api.marketincer.com/api/v1/contracts/generate \
  -H "Content-Type: application/json" \
  -d '{
    "description": "nda between microsoft and john for 6 months confidential information",
    "save_contract": true
  }'
```

**Expected Response:**
- Extracts parties: Microsoft, John
- Extracts duration: 6 months
- Extracts contract type: NDA
- Generates personalized NDA

### Example 4: Employment Contract
```bash
curl -X POST https://api.marketincer.com/api/v1/contracts/generate \
  -H "Content-Type: application/json" \
  -d '{
    "description": "employment contract for software engineer position with salary of rs 80000 in mumbai",
    "save_contract": true
  }'
```

**Expected Response:**
- Extracts amount: Rs 80000
- Extracts location: Mumbai
- Extracts contract type: Employment Contract
- Generates employment contract with Mumbai jurisdiction

## Entity Extraction Patterns

### Parties
- "between X and Y"
- "agreement with X"
- "X and Y contract"

### Amounts
- Rs 5000, Rs. 5,000
- ₹5000
- $5000
- 5000 rupees
- payment of 5000

### Dates
- today, tomorrow, yesterday
- 15/12/2024, 15-12-2024
- December 15, 2024
- effective today
- starting tomorrow

### Companies
- Nike, Google, Microsoft, Apple, Amazon, etc.
- Any capitalized words that look like company names

### Locations
- India, USA, UK, Canada
- Mumbai, Delhi, Bangalore, Chennai
- Used for jurisdiction and governing law

### Contract Types
- service, consulting, freelance → Service Agreement
- nda, confidential, non-disclosure → NDA
- influencer, social media, brand → Influencer Agreement
- employment, job, hiring → Employment Contract
- collaboration, partnership → Collaboration Agreement

## API Response Format

```json
{
  "success": true,
  "message": "Service Agreement generated successfully between Nike and Pramod, for 5000. I've automatically extracted and incorporated the key details from your request.",
  "contract_type": "Service Agreement",
  "generation_method": "ai",
  "extracted_entities": {
    "parties": ["Nike", "Pramod"],
    "amounts": ["5000"],
    "dates": ["December 17, 2024"],
    "companies": ["Nike"],
    "contract_types": ["Service Agreement"]
  },
  "contract": {
    "id": 123,
    "name": "Nike - Service Agreement - December 2024",
    "content": "SERVICE AGREEMENT\n\nThis Service Agreement...",
    "description": "generate service agreement between nike and pramod on date of rs 5000",
    "contract_type": 1,
    "category": 0,
    "status": 0
  },
  "ai_log": {
    "id": 456,
    "status": "completed",
    "created_at": "2024-12-17T18:00:00Z"
  }
}
```

## Testing Checklist

- [ ] Entity extraction works for parties
- [ ] Amount extraction supports multiple currencies
- [ ] Date extraction handles relative dates (today/tomorrow)
- [ ] Company names are properly identified
- [ ] Contract types are correctly determined
- [ ] Personalized contract names are generated
- [ ] Response messages show extracted entities
- [ ] Template fallback works with personalization
- [ ] API response includes extracted_entities field
- [ ] Generated contracts incorporate extracted information

## Benefits

1. **ChatGPT-like Experience**: Natural language input processing
2. **Automatic Intelligence**: No manual entity specification needed
3. **Personalized Output**: Contracts use actual names, amounts, dates
4. **Transparent Processing**: Users see what the system understood
5. **Fallback Support**: Even template generation is personalized
6. **Better UX**: Conversational, intelligent responses