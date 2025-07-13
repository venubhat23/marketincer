# Quick Setup Guide for AI Contract Generation

## Problem Fixed

Your AI contract generation was not working as expected because it was using hardcoded templates instead of dynamically generating content based on your description. The system has been completely redesigned to work like ChatGPT - it now takes your description and generates appropriate contract content.

## What Changed

1. **Removed Hugging Face dependency** (as you requested)
2. **Improved OpenAI integration** with better prompts
3. **Added multiple AI service options** (OpenAI, Groq, Anthropic)
4. **Created smart template fallback** for when AI services are unavailable
5. **Added entity extraction** to parse key information from descriptions

## Quick Start

### Option 1: Use OpenAI (Recommended)

1. Get an OpenAI API key from https://platform.openai.com/
2. Set the environment variable:
   ```bash
   export OPENAI_API_KEY=your_openai_api_key_here
   ```
3. Restart your Rails server
4. Test your API - it should now work dynamically!

### Option 2: Use Groq (Free Alternative)

1. Get a free Groq API key from https://console.groq.com/
2. Set the environment variable:
   ```bash
   export GROQ_API_KEY=your_groq_api_key_here
   export USE_SIMPLE_AI=true
   ```
3. Restart your Rails server

### Option 3: Use Templates Only (No AI API needed)

1. Set the environment variable:
   ```bash
   export USE_SIMPLE_AI=true
   ```
2. Restart your Rails server
3. The system will use smart templates based on your description

## Test Your Setup

Try your original request:

```bash
curl -X POST http://localhost:3001/api/v1/contracts/generate \
  -H "Content-Type: application/json" \
  -d '{
    "name": "collaboration agreement",
    "description": "generate collaboration agreement between adidas and ram for 1000dollar for 1 week for 7 videos content post",
    "use_template": false
  }'
```

## Expected Results

The system will now:
- Extract "Adidas" and "Ram" as the parties
- Identify "$1000" as the payment amount
- Recognize "1 week" as the duration
- Detect "7 videos" as the deliverables
- Generate a professional contract with these details

## If You Want to Force Simple AI Service

Add `"use_simple_ai": true` to your request:

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

## Troubleshooting

1. **No AI API Key**: The system will fall back to smart templates
2. **API Rate Limits**: The system will retry and fall back to templates
3. **Network Issues**: The system will use template generation
4. **Check Logs**: Look at your Rails logs to see which service is being used

## Key Features

- ✅ **Dynamic Content**: No more hardcoded responses
- ✅ **Entity Extraction**: Automatically finds parties, amounts, timelines
- ✅ **Multiple AI Options**: OpenAI, Groq, Anthropic, or templates
- ✅ **Reliable Fallback**: Always generates a contract
- ✅ **Easy Configuration**: Simple environment variables

Your API should now work exactly like ChatGPT - providing dynamic responses based on your description!