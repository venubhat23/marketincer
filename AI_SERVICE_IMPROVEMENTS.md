# AI Contract Generation Service Improvements

## Overview

The AI contract generation service has been completely redesigned to provide more reliable, dynamic contract generation based on user descriptions. The service now properly interprets the description and generates appropriate contracts instead of using hardcoded templates.

## Key Changes Made

### 1. Updated AiContractGenerationService

**File**: `app/services/ai_contract_generation_service.rb`

**Improvements**:
- **Removed Hugging Face dependency**: The service no longer relies on Hugging Face models
- **Better OpenAI integration**: Improved prompts and error handling for OpenAI API calls
- **Smart template fallback**: If OpenAI is not available, the service uses intelligent template generation
- **Entity extraction**: Automatically extracts key information from descriptions (parties, amounts, timelines, etc.)
- **Dynamic content generation**: Generates contracts based on the actual description provided

**Key Features**:
- Extracts party names (e.g., "Adidas", "Ram")
- Identifies payment amounts (e.g., "$1000", "1000dollar")
- Detects time periods (e.g., "1 week", "7 days")
- Recognizes deliverable counts (e.g., "7 videos", "5 posts")
- Determines contract type from keywords

### 2. New SimpleAiService

**File**: `app/services/simple_ai_service.rb`

**Features**:
- **Alternative AI models**: Supports Groq API and Anthropic (Claude) API
- **Lightweight fallback**: Uses smart template generation when AI APIs are unavailable
- **Easy configuration**: Simple environment variable configuration
- **Multiple AI providers**: Tries different AI services in order of preference

**Supported AI APIs**:
- **Groq API**: Uses Llama 3 model (fast and free)
- **Anthropic API**: Uses Claude 3 Sonnet
- **Template Generation**: Intelligent fallback system

### 3. Updated Controller Integration

**File**: `app/controllers/api/v1/contracts_controller.rb`

**Changes**:
- Added option to use SimpleAiService via parameter `use_simple_ai=true`
- Added environment variable `USE_SIMPLE_AI=true` to globally switch services
- Better logging to track which service is being used
- Improved error handling and response formatting

## Usage Examples

### 1. Using the Default Service

```bash
curl -X POST http://localhost:3001/api/v1/contracts/generate \
  -H "Content-Type: application/json" \
  -d '{
    "name": "collaboration agreement",
    "description": "generate collaboration agreement between adidas and ram for 1000dollar for 1 week for 7 videos content post",
    "use_template": false
  }'
```

### 2. Using the Simple AI Service

```bash
curl -X POST http://localhost:3001/api/v1/contracts/generate \
  -H "Content-Type: application/json" \
  -d '{
    "name": "collaboration agreement",
    "description": "generate collaboration agreement between adidas and ram for 1000dollar for 1 week for 7 videos content post",
    "use_template": false,
    "use_simple_ai": true
  }'
```

### 3. Environment Variable Configuration

Set `USE_SIMPLE_AI=true` in your environment to use the simple AI service by default:

```bash
export USE_SIMPLE_AI=true
```

## Configuration

### OpenAI Configuration

Set your OpenAI API key:

```bash
export OPENAI_API_KEY=your_openai_api_key_here
```

### Groq Configuration (Alternative)

Set your Groq API key for the Simple AI Service:

```bash
export GROQ_API_KEY=your_groq_api_key_here
```

### Anthropic Configuration (Alternative)

Set your Anthropic API key for the Simple AI Service:

```bash
export ANTHROPIC_API_KEY=your_anthropic_api_key_here
```

## Expected Response Format

The API will now return dynamic content based on your description:

```json
{
  "success": true,
  "message": "AI response generated successfully",
  "contract_type": null,
  "generation_method": "direct_ai",
  "ai_log": {
    "id": 76,
    "contract_id": null,
    "description": "generate collaboration agreement between adidas and ram for 1000dollar for 1 week for 7 videos content post",
    "status": 2,
    "error_message": null,
    "has_content": true,
    "created_at": "2025-07-13T06:35:26.154Z",
    "updated_at": "2025-07-13T06:35:33.656Z"
  },
  "contract_content": "**COLLABORATION AGREEMENT**\n\nThis Collaboration Agreement (\"Agreement\") is made and entered into on **[Date]**, by and between:\n\n**Adidas**, having its principal place of business at [Address], hereinafter referred to as the \"Brand\",\n\n**AND**\n\n**Ram**, an individual content creator, residing at [Address], hereinafter referred to as the \"Influencer\".\n\n### 1. **Scope of Collaboration**\n\nThe Brand engages the Influencer to create and publish **7 video content posts** on the Influencer's social media platforms over a period of **1 week(s)**.\n\n### 2. **Deliverables**\n\n* Influencer shall create **7 original video posts** as specified.\n* Content shall be posted on platforms agreed by both parties (e.g., Instagram, YouTube, TikTok, etc.).\n* Content shall remain live for a minimum of **30 days** post-publication.\n\n### 3. **Compensation**\n\n* The Brand agrees to pay the Influencer a total of **$1000** for the services described above.\n* Payment will be made **within 5 business days** after completion of the campaign and submission of all deliverables.\n\n### 4. **Timeline**\n\n* Campaign duration: **1 week(s)** starting from **[Start Date]** to **[End Date]**.\n* Posting schedule to be mutually agreed upon before the start of the campaign.\n\n[... rest of the contract with proper legal clauses ...]"
}
```

## Key Improvements

1. **Dynamic Content**: The contract content is now generated based on the actual description provided
2. **Entity Extraction**: Automatically extracts and uses party names, amounts, timelines from the description
3. **Multiple AI Options**: Choose between OpenAI, Groq, Anthropic, or smart templates
4. **Better Error Handling**: Graceful fallbacks when AI services are unavailable
5. **Improved Logging**: Better tracking of which service is being used and why
6. **No Hardcoded Content**: All content is dynamically generated based on input

## Troubleshooting

### If AI Generation Fails

1. **Check API Keys**: Ensure your AI service API keys are correctly set
2. **Check Logs**: Look at the Rails logs to see which service is being used
3. **Use Simple AI**: Try setting `use_simple_ai=true` in your request
4. **Template Fallback**: The service will always generate a contract, even if AI APIs fail

### Common Issues

1. **OpenAI API Key Missing**: Service will fall back to template generation
2. **Rate Limiting**: AI services may have rate limits; the service will retry with exponential backoff
3. **Network Issues**: Service will fall back to template generation if API calls fail

## Testing

To test the services, you can use the provided test script:

```bash
ruby test_ai_service.rb
```

This will test the SimpleAiService with the same description format you provided.

## Recommendations

1. **For Production**: Use OpenAI API for best results
2. **For Development/Testing**: Use Groq API (free tier available)
3. **For Backup**: The template system provides reliable fallback
4. **For Cost Control**: Use environment variables to switch between services

The updated system now provides ChatGPT-like functionality where the AI generates dynamic content based on your description, exactly as requested.