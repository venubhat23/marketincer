# Enhanced AI Contract Generation API

## Overview

The enhanced AI contract generation API at `https://api.marketincer.com/api/v1/contracts/generate` now supports natural language processing to automatically extract parties, amounts, contract types, and dates from user input, similar to ChatGPT.

## Features

✅ **Automatic Entity Extraction**: Extracts parties, amounts, contract types, and dates from natural language input
✅ **Professional Formatting**: Generates beautifully formatted contracts with proper legal structure
✅ **Smart Party Role Detection**: Automatically determines which party is the company and which is the individual
✅ **Multiple Contract Types**: Supports Service Agreements, Influencer Agreements, NDAs, Employment Contracts, and Sponsorship Agreements
✅ **Currency Formatting**: Properly formats amounts with currency symbols and written numbers
✅ **Date Handling**: Supports relative dates (today, tomorrow) and specific date formats
✅ **Company Address Database**: Automatically includes correct addresses for major companies like Nike, Google, Microsoft, etc.

## API Endpoint

```
POST https://api.marketincer.com/api/v1/contracts/generate
```

## Request Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `description` | String | Yes | Natural language description of the contract |
| `save_contract` | Boolean | No | Whether to save the generated contract (default: false) |
| `use_template` | Boolean | No | Whether to use template generation (default: false) |
| `template_id` | String | No | Template ID if using template generation |

## Example Usage

### Example 1: Service Agreement (Your specific example)

**Request:**
```bash
curl -X POST https://api.marketincer.com/api/v1/contracts/generate \
  -H "Content-Type: application/json" \
  -d '{
    "description": "generate service agreement between nike and pramod on date of rs 5000",
    "save_contract": false
  }'
```

**Response:**
```json
{
  "success": true,
  "message": "Service Agreement generated successfully",
  "contract_type": "Service Agreement",
  "generation_method": "enhanced_template",
  "contract_content": "Here's a professional **Service Agreement** between Nike and Pramod for ₹5000 (Rupees Five Thousand only), effective December 30, 2024:\n\n---\n\n**SERVICE AGREEMENT**\n\nThis Service Agreement (\"Agreement\") is made and entered into on **December 30, 2024**, by and between:\n\n**Nike**\nOne Bowerman Drive, Beaverton, OR 97005, USA\n(Hereinafter referred to as \"Company\")\n\nAND\n\n**Pramod**\n[Address of Pramod]\n(Hereinafter referred to as \"Service Provider\")\n\n--- ... [full contract content]"
}
```

### Example 2: Influencer Agreement

**Request:**
```bash
curl -X POST https://api.marketincer.com/api/v1/contracts/generate \
  -H "Content-Type: application/json" \
  -d '{
    "description": "create influencer agreement between nike and sarah for brand collaboration worth $2000",
    "save_contract": true
  }'
```

### Example 3: NDA

**Request:**
```bash
curl -X POST https://api.marketincer.com/api/v1/contracts/generate \
  -H "Content-Type: application/json" \
  -d '{
    "description": "generate nda between google and john for confidential project discussion",
    "save_contract": false
  }'
```

## Supported Natural Language Patterns

The API can understand various natural language patterns:

### Party Extraction
- `"between Nike and Pramod"`
- `"agreement with John"`
- `"Nike and Sarah contract"`
- `"generate service agreement between Company A and Person B"`

### Amount Extraction
- `"rs 5000"` or `"Rs. 5,000"`
- `"₹5000"` or `"$2000"`
- `"worth 10000 rupees"`
- `"on date of rs 5000"`
- `"amount of $1500"`

### Contract Type Extraction
- `"service agreement"`
- `"influencer agreement"`
- `"nda"` or `"non-disclosure agreement"`
- `"employment contract"`
- `"sponsorship agreement"`

### Date Extraction
- `"today"` or `"tomorrow"`
- `"on date of"` (uses current date)
- `"January 15, 2024"`
- `"15/01/2024"`

## Contract Types Supported

### 1. Service Agreement
**Triggered by:** `service`, `consulting`, `freelance`, `contractor`, `work`
**Features:** 
- Professional service scope
- Payment terms
- Deliverables and timeline
- Intellectual property rights
- Termination clauses

### 2. Influencer Agreement
**Triggered by:** `influencer`, `social media`, `brand collaboration`, `promotion`, `marketing`
**Features:**
- Content requirements
- Platform specifications
- FTC compliance
- Usage rights
- Exclusivity clauses

### 3. NDA (Non-Disclosure Agreement)
**Triggered by:** `nda`, `confidential`, `non-disclosure`, `secret`, `proprietary`
**Features:**
- Confidentiality obligations
- Information definition
- Exceptions
- Term and return of information
- Remedies

### 4. Employment Contract
**Triggered by:** `employment`, `job`, `hiring`, `salary`, `position`
**Features:**
- Position and duties
- Compensation
- Benefits
- Working hours
- Termination conditions

### 5. Sponsorship Agreement
**Triggered by:** `sponsorship`, `sponsor`, `event`, `partnership`
**Features:**
- Sponsorship details
- Sponsor benefits
- Payment terms
- Obligations
- Intellectual property

## Smart Features

### 1. Company Address Database
The API automatically includes correct addresses for major companies:
- Nike: "One Bowerman Drive, Beaverton, OR 97005, USA"
- Google: "1600 Amphitheatre Parkway, Mountain View, CA 94043, USA"
- Microsoft: "One Microsoft Way, Redmond, WA 98052, USA"
- Apple: "One Apple Park Way, Cupertino, CA 95014, USA"
- Amazon: "410 Terry Ave N, Seattle, WA 98109, USA"
- Facebook/Meta: "1 Hacker Way, Menlo Park, CA 94301, USA"

### 2. Currency Formatting
Amounts are automatically formatted with proper currency symbols and written numbers:
- Input: `"rs 5000"` → Output: `"₹5000 (Rupees Five Thousand only)"`
- Input: `"$2000"` → Output: `"$2000 (US Dollars Two Thousand only)"`

### 3. Date Formatting
Dates are automatically formatted consistently:
- Input: `"today"` → Output: `"December 30, 2024"`
- Input: `"15/01/2024"` → Output: `"January 15, 2024"`

## Error Handling

The API handles various error scenarios:

```json
{
  "success": false,
  "message": "Description is required for AI contract generation",
  "error_code": "MISSING_DESCRIPTION"
}
```

Common error codes:
- `MISSING_DESCRIPTION`: Description parameter is required
- `DESCRIPTION_TOO_SHORT`: Description must be at least 10 characters
- `AI_GENERATION_FAILED`: AI service failed to generate content
- `TEMPLATE_NOT_FOUND`: Template ID not found (when using templates)

## Testing

You can test the API with the example you provided:

```bash
curl -X POST https://api.marketincer.com/api/v1/contracts/generate \
  -H "Content-Type: application/json" \
  -d '{
    "description": "generate service agreement between nike and pramod on date of rs 5000"
  }'
```

This will return a professionally formatted service agreement with:
- Nike as the company party
- Pramod as the service provider
- ₹5000 as the compensation amount
- Today's date as the effective date
- Complete legal structure with all necessary clauses

## Advanced Usage

### Save Contract
To save the generated contract to the database:

```json
{
  "description": "generate service agreement between nike and pramod on date of rs 5000",
  "save_contract": true
}
```

### Use with Templates
For faster generation with predefined templates:

```json
{
  "description": "generate service agreement between nike and pramod on date of rs 5000",
  "use_template": true,
  "template_id": "service_agreement_template"
}
```

## Integration Notes

1. **Authentication**: Make sure to include proper authentication headers if required by your API
2. **Rate Limiting**: The API may have rate limits in place
3. **Content Review**: Always review generated contracts before use and customize as needed
4. **Legal Compliance**: Consult with legal counsel for important contracts

## Changelog

### v2.0 (Current)
- Added natural language processing for automatic entity extraction
- Enhanced contract formatting with professional structure
- Added support for multiple contract types
- Implemented smart party role detection
- Added company address database
- Enhanced currency and date formatting
- Improved error handling and validation

### v1.0
- Basic AI contract generation
- Template-based generation
- OpenAI integration
- Hugging Face fallback

---

*This API generates contracts automatically. Please review all terms carefully and consult with legal counsel before signing. Customize the specific terms, addresses, and details as needed for your particular situation.*