# app/services/ai_contract_generation_service.rb
class AiContractGenerationService
  API_URL = 'https://api-inference.huggingface.co/models/microsoft/DialoGPT-medium'
  API_KEY = Rails.application.credentials.huggingface_api_key || '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'
  
  def initialize(description)
    @description = description
    @timeout = 60
    @max_retries = 3
  end
  
  def generate
    retries = 0
    
    begin
      # Try to generate with Hugging Face API first
      ai_generated_content = call_huggingface_api(@description)
      
      if ai_generated_content && !ai_generated_content.empty? && valid_contract_content?(ai_generated_content)
        return format_ai_contract(ai_generated_content)
      else
        # Fallback to template if AI fails or content is invalid
        Rails.logger.warn "AI generation failed or invalid, falling back to template"
        return generate_contract_template
      end
    rescue => e
      retries += 1
      if retries <= @max_retries
        Rails.logger.warn "AI Contract Generation attempt #{retries} failed: #{e.message}. Retrying..."
        sleep(2 ** retries) # Exponential backoff
        retry
      else
        Rails.logger.error "AI Contract Generation failed after #{@max_retries} attempts: #{e.message}"
        # Fallback to template on error
        generate_contract_template
      end
    end
  end
  
  private
  
  def call_huggingface_api(description)
    require 'net/http'
    require 'json'
    
    uri = URI(API_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = @timeout
    http.open_timeout = 30
    
    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{API_KEY}"
    request['Content-Type'] = 'application/json'
    request['User-Agent'] = 'ContractGenerator/1.0'
    
    # Craft a detailed prompt for contract generation
    prompt = build_contract_prompt(description)
    
    request.body = {
      inputs: prompt,
      parameters: {
        max_length: 2000,
        temperature: 0.7,
        do_sample: true,
        top_p: 0.9,
        repetition_penalty: 1.2,
        num_return_sequences: 1
      },
      options: {
        wait_for_model: true,
        use_cache: false
      }
    }.to_json
    
    response = http.request(request)
    
    case response.code
    when '200'
      result = JSON.parse(response.body)
      extract_generated_content(result, prompt)
    when '503'
      Rails.logger.warn "Model is loading, retrying..."
      sleep(10)
      raise "Model is loading"
    when '429'
      Rails.logger.warn "Rate limit exceeded"
      raise "Rate limit exceeded"
    else
      Rails.logger.error "Hugging Face API error: #{response.code} - #{response.body}"
      raise "API Error: #{response.code}"
    end
  end
  
  def build_contract_prompt(description)
    contract_type = determine_contract_type(description)
    
    <<~PROMPT
      Create a comprehensive legal contract based on this description: #{description}
      
      Contract Type: #{contract_type}
      
      The contract must include:
      1. Clear title and party identification
      2. Detailed scope of work/services
      3. Specific payment terms and amounts
      4. Timeline with deliverables and deadlines
      5. Responsibilities of each party
      6. Intellectual property rights
      7. Termination and cancellation clauses
      8. Dispute resolution procedures
      9. Governing law and jurisdiction
      10. Signature blocks
      
      Generate a professional, legally structured contract:
      
      CONTRACT AGREEMENT
      
      This Agreement is entered into on [DATE] between [PARTY_A] and [PARTY_B].
      
    PROMPT
  end
  
  def determine_contract_type(description)
    description_lower = description.downcase
    
    return "Influencer Collaboration" if description_lower.include?("influencer") || description_lower.include?("social media")
    return "Sponsorship Agreement" if description_lower.include?("sponsor") || description_lower.include?("event")
    return "Service Agreement" if description_lower.include?("service") || description_lower.include?("freelance")
    return "Employment Contract" if description_lower.include?("employ") || description_lower.include?("job")
    return "Non-Disclosure Agreement" if description_lower.include?("nda") || description_lower.include?("confidential")
    return "Gifting Agreement" if description_lower.include?("gift") || description_lower.include?("product")
    
    "General Service Agreement"
  end
  
  def extract_generated_content(result, prompt)
    generated_text = nil
    
    # Handle different response formats from Hugging Face
    if result.is_a?(Array) && result.first.is_a?(Hash)
      generated_text = result.first['generated_text'] || result.first['text']
    elsif result.is_a?(Hash)
      generated_text = result['generated_text'] || result['text'] || result.dig(0, 'generated_text')
    end
    
    return nil unless generated_text
    
    # Clean and extract the contract content
    extract_contract_content(generated_text, prompt)
  end
  
  def extract_contract_content(generated_text, prompt)
    # Remove the original prompt from the generated text
    contract_content = generated_text.gsub(prompt, '').strip
    
    # Clean up formatting
    contract_content = contract_content
      .gsub(/\n{3,}/, "\n\n")           # Replace multiple newlines
      .gsub(/^\s+/, '')                 # Remove leading whitespace
      .gsub(/\t/, '    ')               # Replace tabs with spaces
      .gsub(/\r\n/, "\n")               # Normalize line endings
      .strip
    
    # Ensure minimum content requirements
    return nil if contract_content.length < 300
    return nil unless contract_content.match?(/agreement|contract/i)
    return nil unless contract_content.include?('PARTY') || contract_content.include?('Party')
    
    # Add proper contract structure if missing
    unless contract_content.match?(/^\s*\w+\s+(AGREEMENT|CONTRACT)/i)
      contract_content = "CONTRACT AGREEMENT\n\n" + contract_content
    end
    
    contract_content
  end
  
  def valid_contract_content?(content)
    return false if content.blank? || content.length < 300
    
    # Check for essential contract elements
    essential_elements = [
      /agreement|contract/i,
      /part(y|ies)/i,
      /terms|conditions/i
    ]
    
    essential_elements.all? { |pattern| content.match?(pattern) }
  end
  
  def format_ai_contract(ai_content)
    current_date = Date.current.strftime('%B %d, %Y')
    
    # Ensure proper formatting
    formatted_content = ai_content.strip
    
    # Add signature section if not present
    unless formatted_content.include?('Signature')
      formatted_content += "\n\n" + signature_section
    end
    
    # Add generation metadata
    formatted_content += "\n\n" + generation_metadata
    
    formatted_content.strip
  end
  
  def signature_section
    <<~SIGNATURE
      SIGNATURE SECTION
      
      By signing below, both parties acknowledge that they have read, understood, and agree to be bound by the terms and conditions set forth in this contract.
      
      PARTY A:                               PARTY B:
      
      _____________________                  _____________________
      Signature                             Signature
      
      _____________________                  _____________________
      Print Name                            Print Name
      
      _____________________                  _____________________
      Title                                 Title
      
      _____________________                  _____________________
      Date                                  Date
    SIGNATURE
  end
  
  def generation_metadata
    <<~METADATA
      ---
      Contract Generation Information:
      - Generated on: #{Time.current.strftime('%Y-%m-%d %H:%M:%S')}
      - Generation method: AI-assisted
      - Based on description: #{@description.truncate(100)}
      - This is a draft contract and should be reviewed by legal counsel before execution
    METADATA
  end
  
  def generate_contract_template
    current_date = Date.current.strftime('%B %d, %Y')
    contract_type = determine_contract_type(@description)
    
    template_content = case contract_type.downcase
    when /influencer/
      influencer_template
    when /sponsor/
      sponsorship_template
    when /service/
      service_template
    when /employment/
      employment_template
    when /nda|confidential/
      nda_template
    when /gift/
      gifting_template
    else
      general_template
    end
    
    template_content + "\n\n" + signature_section + "\n\n" + generation_metadata
  end
  
  def influencer_template
    <<~TEMPLATE
      INFLUENCER COLLABORATION AGREEMENT
      
      This Influencer Collaboration Agreement is entered into on #{Date.current.strftime('%B %d, %Y')} between [BRAND_NAME] ("Brand") and [INFLUENCER_NAME] ("Influencer").
      
      WHEREAS, Brand desires to engage Influencer to create and publish content promoting Brand's products/services;
      WHEREAS, Influencer agrees to create authentic content in accordance with this Agreement;
      
      NOW, THEREFORE, the parties agree as follows:
      
      1. CAMPAIGN DETAILS
      Description: #{@description}
      Campaign Duration: [START_DATE] to [END_DATE]
      
      2. DELIVERABLES
      Influencer agrees to create and publish:
      - [NUMBER] Instagram posts with brand mentions
      - [NUMBER] Instagram stories featuring products
      - [OTHER SPECIFIC DELIVERABLES]
      
      3. CONTENT REQUIREMENTS
      - All content must be original and authentic
      - Content must align with Brand's values and guidelines
      - High-quality images/videos as per brand standards
      - Appropriate hashtags and brand mentions
      
      4. COMPENSATION
      - Total Compensation: $[AMOUNT]
      - Payment Schedule: [PAYMENT_TERMS]
      - Additional Benefits: [PRODUCTS/SERVICES]
      
      5. FTC COMPLIANCE
      - Influencer must include proper disclosure (#ad, #sponsored, #partnership)
      - All content must comply with FTC guidelines
      
      6. CONTENT OWNERSHIP & USAGE RIGHTS
      - Influencer retains copyright to original content
      - Brand receives perpetual license to use content for marketing
      - Content may be cross-posted on Brand's social channels
      
      7. PERFORMANCE METRICS
      - Minimum engagement requirements: [METRICS]
      - Reporting requirements: [REPORTING_SCHEDULE]
      
      8. TERMINATION
      Either party may terminate with [NOTICE_PERIOD] written notice.
      
      9. GOVERNING LAW
      This Agreement shall be governed by [STATE/COUNTRY] law.
    TEMPLATE
  end
  
  def sponsorship_template
    <<~TEMPLATE
      SPONSORSHIP AGREEMENT
      
      This Sponsorship Agreement is entered into on #{Date.current.strftime('%B %d, %Y')} between [SPONSOR_NAME] ("Sponsor") and [RECIPIENT_NAME] ("Recipient").
      
      PURPOSE: #{@description}
      
      1. SPONSORSHIP DETAILS
      - Event/Campaign: [EVENT_NAME]
      - Date(s): [EVENT_DATES]
      - Location: [LOCATION]
      - Sponsorship Level: [TIER_LEVEL]
      
      2. SPONSORSHIP INVESTMENT
      - Total Sponsorship Amount: $[AMOUNT]
      - Payment Schedule: [PAYMENT_TERMS]
      - In-kind Contributions: [IN_KIND_VALUE]
      
      3. SPONSOR BENEFITS
      - Logo placement on event materials
      - [NUMBER] complimentary tickets/passes
      - Social media mentions and tags
      - Email marketing inclusion
      - Speaking opportunities: [DETAILS]
      - Booth/exhibit space: [SPECIFICATIONS]
      
      4. RECIPIENT OBLIGATIONS
      - Provide marketing materials as specified
      - Deliver promised exposure and benefits
      - Submit post-event report with metrics
      - Maintain professional event standards
      
      5. MARKETING & PROMOTION
      - Pre-event promotion timeline
      - Social media requirements
      - Press release inclusion
      - Website listing requirements
      
      6. CANCELLATION POLICY
      - Cancellation by Recipient: [TERMS]
      - Cancellation by Sponsor: [TERMS]
      - Force Majeure provisions
      
      7. LIABILITY & INSURANCE
      - Insurance requirements
      - Liability limitations
      - Indemnification clauses
    TEMPLATE
  end
  
  def service_template
    <<~TEMPLATE
      SERVICE PROVIDER AGREEMENT
      
      This Service Agreement is entered into on #{Date.current.strftime('%B %d, %Y')} between [CLIENT_NAME] ("Client") and [SERVICE_PROVIDER_NAME] ("Service Provider").
      
      SERVICE DESCRIPTION: #{@description}
      
      1. SCOPE OF SERVICES
      Service Provider agrees to provide the following services:
      - [DETAILED_SERVICE_DESCRIPTION]
      - [SPECIFIC_DELIVERABLES]
      - [PERFORMANCE_STANDARDS]
      
      2. PROJECT TIMELINE
      - Project Start Date: [START_DATE]
      - Key Milestones: [MILESTONE_DATES]
      - Expected Completion: [END_DATE]
      - Delivery Schedule: [DELIVERY_TERMS]
      
      3. COMPENSATION & PAYMENT
      - Total Project Fee: $[AMOUNT]
      - Payment Structure: [HOURLY/FIXED/MILESTONE]
      - Payment Schedule: [PAYMENT_TERMS]
      - Expenses: [EXPENSE_POLICY]
      
      4. CLIENT RESPONSIBILITIES
      - Provide necessary information and materials
      - Timely feedback and approvals
      - Access to required systems/resources
      - [OTHER_CLIENT_OBLIGATIONS]
      
      5. INTELLECTUAL PROPERTY
      - Work product ownership
      - License grants
      - Pre-existing IP protection
      - Confidentiality obligations
      
      6. QUALITY STANDARDS
      - Acceptance criteria
      - Revision process
      - Quality assurance procedures
      
      7. TERMINATION
      - Termination for convenience
      - Termination for cause
      - Final payment obligations
      
      8. LIMITATION OF LIABILITY
      Service Provider's liability limited to total contract amount.
    TEMPLATE
  end
  
  def employment_template
    <<~TEMPLATE
      EMPLOYMENT AGREEMENT
      
      This Employment Agreement is entered into on #{Date.current.strftime('%B %d, %Y')} between [COMPANY_NAME] ("Company") and [EMPLOYEE_NAME] ("Employee").
      
      POSITION DESCRIPTION: #{@description}
      
      1. EMPLOYMENT TERMS
      - Position: [JOB_TITLE]
      - Department: [DEPARTMENT]
      - Start Date: [START_DATE]
      - Employment Type: [FULL_TIME/PART_TIME/CONTRACT]
      
      2. COMPENSATION PACKAGE
      - Base Salary: $[ANNUAL_SALARY]
      - Pay Frequency: [MONTHLY/BI_WEEKLY]
      - Bonus Structure: [BONUS_TERMS]
      - Benefits: [BENEFITS_PACKAGE]
      
      3. WORK SCHEDULE
      - Standard Hours: [HOURS_PER_WEEK]
      - Work Schedule: [SCHEDULE_DETAILS]
      - Remote Work Policy: [REMOTE_TERMS]
      - Overtime Policy: [OVERTIME_TERMS]
      
      4. JOB RESPONSIBILITIES
      - Primary duties and responsibilities
      - Performance expectations
      - Reporting structure
      - Authority and decision-making scope
      
      5. CONFIDENTIALITY & NON-DISCLOSURE
      - Protection of company information
      - Non-disclosure obligations
      - Return of company property
      
      6. NON-COMPETE & NON-SOLICITATION
      - Non-compete restrictions: [DURATION/GEOGRAPHY]
      - Non-solicitation of clients/employees
      - Reasonable scope and limitations
      
      7. TERMINATION
      - At-will employment provisions
      - Notice requirements
      - Severance provisions
      - Post-termination obligations
      
      8. BENEFITS & POLICIES
      - Health insurance
      - Retirement plans
      - Vacation and sick leave
      - Professional development
    TEMPLATE
  end
  
  def nda_template
    <<~TEMPLATE
      NON-DISCLOSURE AGREEMENT (NDA)
      
      This Non-Disclosure Agreement is entered into on #{Date.current.strftime('%B %d, %Y')} between [DISCLOSING_PARTY] ("Disclosing Party") and [RECEIVING_PARTY] ("Receiving Party").
      
      PURPOSE: #{@description}
      
      1. DEFINITION OF CONFIDENTIAL INFORMATION
      "Confidential Information" includes all non-public, proprietary information disclosed by either party, including but not limited to:
      - Business plans and strategies
      - Financial information
      - Technical data and specifications
      - Customer lists and information
      - Marketing plans and strategies
      - [OTHER_SPECIFIC_INFORMATION]
      
      2. OBLIGATIONS OF RECEIVING PARTY
      Receiving Party agrees to:
      - Maintain strict confidentiality
      - Use information solely for agreed purposes
      - Not disclose to third parties without written consent
      - Implement reasonable security measures
      - Limit access to authorized personnel only
      
      3. EXCEPTIONS
      This agreement does not apply to information that:
      - Is publicly available through no breach of this agreement
      - Was known to Receiving Party prior to disclosure
      - Is independently developed without use of Confidential Information
      - Is required to be disclosed by law or court order
      
      4. DURATION
      - This agreement remains effective for [DURATION] years
      - Obligations survive termination of any business relationship
      - Return or destruction of materials upon termination
      
      5. REMEDIES
      - Breach may cause irreparable harm
      - Injunctive relief may be sought without posting bond
      - Monetary damages may be insufficient remedy
      
      6. GOVERNING LAW
      This agreement is governed by [JURISDICTION] law.
    TEMPLATE
  end
  
  def gifting_template
    <<~TEMPLATE
      PRODUCT GIFTING AGREEMENT
      
      This Gifting Agreement is entered into on #{Date.current.strftime('%B %d, %Y')} between [BRAND_NAME] ("Brand") and [RECIPIENT_NAME] ("Recipient").
      
      GIFTING PURPOSE: #{@description}
      
      1. GIFTED PRODUCTS
      Brand agrees to provide the following products at no cost:
      - [PRODUCT_LIST]
      - Estimated retail value: $[VALUE]
      - Delivery method: [SHIPPING_DETAILS]
      
      2. RECIPIENT OBLIGATIONS
      In exchange for the gifted products, Recipient agrees to:
      - Create [NUMBER] social media posts featuring products
      - Provide honest and authentic reviews
      - Include proper disclosure hashtags (#gifted, #pr)
      - Tag brand in all related posts
      
      3. CONTENT REQUIREMENTS
      - Minimum [NUMBER] posts within [TIMEFRAME]
      - High-quality images/videos
      - Authentic product experience sharing
      - Compliance with FTC guidelines
      
      4. CONTENT USAGE RIGHTS
      - Recipient retains ownership of created content
      - Brand may repost/share content with proper attribution
      - No exclusive rights granted to Brand
      
      5. NO GUARANTEED PROMOTION
      - Brand understands positive reviews are not guaranteed
      - Recipient maintains editorial independence
      - Honest opinions are encouraged and expected
      
      6. DELIVERY & LOGISTICS
      - Brand covers all shipping and handling costs
      - Delivery timeline: [EXPECTED_DELIVERY]
      - Risk of loss transfers upon delivery
      
      7. COMPLIANCE
      - All posts must comply with platform guidelines
      - Proper disclosure required by law
      - No misleading or false claims
    TEMPLATE
  end
  
  def general_template
    <<~TEMPLATE
      GENERAL AGREEMENT
      
      This Agreement is entered into on #{Date.current.strftime('%B %d, %Y')} between [PARTY_A] and [PARTY_B].
      
      PURPOSE: #{@description}
      
      1. SCOPE OF AGREEMENT
      The parties agree to collaborate on the following:
      - [SPECIFIC_OBJECTIVES]
      - [DELIVERABLES]
      - [PERFORMANCE_STANDARDS]
      
      2. TERMS AND CONDITIONS
      - Duration: [TERM_LENGTH]
      - Key obligations of each party
      - Performance metrics and standards
      - Communication protocols
      
      3. FINANCIAL TERMS
      - Payment structure: [PAYMENT_TERMS]
      - Total value: $[AMOUNT]
      - Payment schedule: [SCHEDULE]
      - Expense allocation: [EXPENSE_TERMS]
      
      4. RESPONSIBILITIES
      Party A Responsibilities:
      - [PARTY_A_OBLIGATIONS]
      
      Party B Responsibilities:
      - [PARTY_B_OBLIGATIONS]
      
      5. INTELLECTUAL PROPERTY
      - Ownership of work product
      - License grants
      - Confidentiality provisions
      
      6. TERMINATION
      - Termination conditions
      - Notice requirements
      - Post-termination obligations
      
      7. DISPUTE RESOLUTION
      - Negotiation requirements
      - Mediation procedures
      - Arbitration clauses
      
      8. GENERAL PROVISIONS
      - Governing law
      - Entire agreement clause
      - Amendment procedures
      - Severability provisions
    TEMPLATE
  end
end