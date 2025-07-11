class AiContractGenerationService
  require 'openai'
  require 'net/http'
  require 'json'
  
  # Primary AI service configuration
  OPENAI_API_KEY = Rails.application.credentials.openai_api_key || ENV['OPENAI_API_KEY']
  HUGGINGFACE_API_KEY = Rails.application.credentials.huggingface_api_key || ENV['HUGGINGFACE_API_KEY'] || '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'
  
  # Fallback Hugging Face model URLs
  HUGGINGFACE_MODELS = [
    'https://api-inference.huggingface.co/models/microsoft/DialoGPT-large',
    'https://api-inference.huggingface.co/models/EleutherAI/gpt-neo-2.7B',
    'https://api-inference.huggingface.co/models/microsoft/DialoGPT-medium',
    'https://api-inference.huggingface.co/models/gpt2'
  ].freeze

  def initialize(description)
    @description = description
    @timeout = 120
    @max_retries = 3
    @openai_client = setup_openai_client if OPENAI_API_KEY.present?
  end

  def generate
    retries = 0

    begin
      # Try OpenAI first (much better quality)
      if @openai_client
        Rails.logger.info "Using OpenAI for contract generation"
        ai_generated_content = generate_with_openai(@description)
        
        if ai_generated_content.present? && valid_contract_content?(ai_generated_content)
          Rails.logger.info("OpenAI contract generated successfully")
          return format_ai_contract(ai_generated_content)
        else
          Rails.logger.warn "OpenAI generation failed, falling back to Hugging Face"
        end
      end

      # Fallback to Hugging Face
      Rails.logger.info "Using Hugging Face for contract generation"
      ai_generated_content = generate_with_huggingface(@description)
      
      if ai_generated_content.present? && valid_contract_content?(ai_generated_content)
        Rails.logger.info("Hugging Face contract generated successfully")
        return format_ai_contract(ai_generated_content)
      else
        Rails.logger.warn "AI generation failed, falling back to intelligent template"
        return generate_intelligent_template
      end
      
    rescue => e
      retries += 1
      if retries <= @max_retries
        Rails.logger.warn "AI Contract Generation attempt #{retries} failed: #{e.message}. Retrying..."
        sleep(2 ** retries)
        retry
      else
        Rails.logger.error "AI Contract Generation failed after #{@max_retries} attempts: #{e.message}"
        generate_intelligent_template
      end
    end
  end

  private

  def setup_openai_client
    return nil unless OPENAI_API_KEY.present?
    
    OpenAI::Client.new(
      access_token: OPENAI_API_KEY,
      request_timeout: @timeout
    )
  rescue => e
    Rails.logger.error "Failed to setup OpenAI client: #{e.message}"
    nil
  end

  def generate_with_openai(description)
    return nil unless @openai_client

    prompt = build_advanced_contract_prompt(description)
    
    response = @openai_client.chat(
      parameters: {
        model: determine_openai_model,
        messages: [
          {
            role: "system",
            content: build_system_prompt
          },
          {
            role: "user", 
            content: prompt
          }
        ],
        max_tokens: 4000,
        temperature: 0.7,
        top_p: 0.9,
        frequency_penalty: 0.3,
        presence_penalty: 0.3
      }
    )

    if response.dig("choices", 0, "message", "content")
      content = response["choices"][0]["message"]["content"]
      clean_and_format_content(content)
    else
      Rails.logger.error "OpenAI API response format unexpected: #{response}"
      nil
    end
    
  rescue => e
    Rails.logger.error "OpenAI API error: #{e.message}"
    nil
  end

  def determine_openai_model
    # Use GPT-4 if available, otherwise GPT-3.5
    models = ['gpt-4', 'gpt-4-turbo-preview', 'gpt-3.5-turbo-16k', 'gpt-3.5-turbo']
    
    # For now, use GPT-3.5-turbo as it's most widely available
    'gpt-3.5-turbo-16k'
  end

  def build_system_prompt
    <<~SYSTEM_PROMPT
      You are an expert legal contract drafting assistant with deep knowledge of contract law, business agreements, and legal documentation standards across multiple jurisdictions including India, US, and UK.

      Your role is to create comprehensive, professional, and legally sound contracts based on user descriptions. You should:

      1. Generate detailed, well-structured contracts with all necessary legal clauses
      2. Include appropriate sections like parties, recitals, terms, conditions, signatures, etc.
      3. Use proper legal terminology and formatting
      4. Ensure contracts are enforceable and protect both parties' interests
      5. Include relevant boilerplate clauses (governing law, dispute resolution, etc.)
      6. Adapt the contract type based on the description (service, employment, NDA, etc.)
      7. Use placeholder values in [BRACKETS] for party-specific information
      8. Include proper legal disclaimers and notices
      9. Follow standard contract structure and formatting conventions
      10. Make contracts comprehensive yet readable

      Always produce complete, professional contracts that would be suitable for actual business use after customization.
    SYSTEM_PROMPT
  end

  def build_advanced_contract_prompt(description)
    contract_type = determine_contract_type(description)
    entities = extract_entities_from_description(description)
    
    # Build entity summary for the prompt
    entity_summary = build_entity_summary(entities)
    
    <<~PROMPT
      Please draft a comprehensive #{contract_type} based on the following requirements:

      **Contract Description:** #{description}

      **Detected Contract Type:** #{contract_type}
      
      #{entity_summary}

      **Requirements:**
      1. Create a complete, professional contract with all necessary legal sections
      2. Include proper contract title, parties identification, and recitals
      3. Add detailed scope of work/services section
      4. Include comprehensive terms and conditions
      5. Add payment terms, timelines, and deliverables (use extracted amounts and dates if available)
      6. Include termination clauses and dispute resolution
      7. Add intellectual property rights clauses if applicable
      8. Include confidentiality provisions if needed
      9. Add proper signature blocks and witness sections
      10. Include governing law and jurisdiction clauses (use extracted locations if available)
      11. Add force majeure and other standard boilerplate clauses
      12. Use placeholder values in [BRACKETS] for customization, but incorporate extracted entities where appropriate
      13. Include legal disclaimers and notices

      **Specific Instructions:**
      #{build_entity_specific_instructions(entities)}
      
      **Specific Focus Areas:**
      - Make it legally sound and enforceable
      - Ensure it protects both parties' interests
      - Include industry-specific clauses if applicable
      - Make it comprehensive yet clear and readable
      - Follow standard legal contract formatting
      - Include all necessary legal protections
      - Personalize using the extracted entities where appropriate

      Please generate a complete, professional contract that would be suitable for actual business use, incorporating the extracted information naturally into the contract structure.
    PROMPT
  end

  def build_entity_summary(entities)
    summary_parts = []
    
    if entities[:parties]&.any?
      summary_parts << "**Identified Parties:** #{entities[:parties].join(' and ')}"
    end
    
    if entities[:companies]&.any?
      summary_parts << "**Companies/Brands:** #{entities[:companies].join(', ')}"
    end
    
    if entities[:amounts]&.any?
      summary_parts << "**Payment Amounts:** #{entities[:amounts].join(', ')}"
    end
    
    if entities[:dates]&.any?
      summary_parts << "**Important Dates:** #{entities[:dates].join(', ')}"
    end
    
    if entities[:durations]&.any?
      summary_parts << "**Contract Duration:** #{entities[:durations].join(', ')}"
    end
    
    if entities[:locations]&.any?
      summary_parts << "**Locations/Jurisdiction:** #{entities[:locations].join(', ')}"
    end
    
    if entities[:contract_types]&.any?
      summary_parts << "**Contract Type Keywords:** #{entities[:contract_types].join(', ')}"
    end
    
    return "**Extracted Information:**\n#{summary_parts.join("\n")}\n" if summary_parts.any?
    ""
  end

  def build_entity_specific_instructions(entities)
    instructions = []
    
    if entities[:parties]&.any?
      party_a = entities[:parties][0] || "[PARTY_A]"
      party_b = entities[:parties][1] || "[PARTY_B]"
      instructions << "- Use '#{party_a}' and '#{party_b}' as the contracting parties instead of generic placeholders"
    end
    
    if entities[:amounts]&.any?
      amount = entities[:amounts].first
      instructions << "- Include payment terms specifying amount of #{amount} (adjust currency and format as appropriate)"
    end
    
    if entities[:dates]&.any?
      date = entities[:dates].first
      instructions << "- Use #{date} as the effective date or reference date in the contract"
    end
    
    if entities[:companies]&.any?
      companies = entities[:companies].join(' and ')
      instructions << "- Reference #{companies} specifically in the contract context"
    end
    
    if entities[:locations]&.any?
      location = entities[:locations].first
      instructions << "- Use #{location} laws for governing law clauses and jurisdiction"
    end
    
    if entities[:durations]&.any?
      duration = entities[:durations].first
      instructions << "- Set contract term/duration to #{duration}"
    end
    
    instructions.any? ? instructions.join("\n") : "- Use standard placeholder values as appropriate"
  end

  def extract_entities_from_description(description)
    entities = {}
    
    # Extract parties/names (looking for patterns like "between X and Y", "with X", etc.)
    parties = extract_parties(description)
    entities[:parties] = parties if parties.any?
    
    # Extract amounts/payments (Rs, $, EUR, etc.)
    amounts = extract_amounts(description)
    entities[:amounts] = amounts if amounts.any?
    
    # Extract dates (today, tomorrow, specific dates, etc.)
    dates = extract_dates(description)
    entities[:dates] = dates if dates.any?
    
    # Extract contract types
    contract_types = extract_contract_keywords(description)
    entities[:contract_types] = contract_types if contract_types.any?
    
    # Extract locations/jurisdictions
    locations = extract_locations(description)
    entities[:locations] = locations if locations.any?
    
    # Extract company/brand names
    companies = extract_companies(description)
    entities[:companies] = companies if companies.any?
    
    # Extract timeframes/durations
    durations = extract_durations(description)
    entities[:durations] = durations if durations.any?
    
    entities
  end

  def extract_parties(description)
    parties = []
    
    # Patterns like "between X and Y", "with X", "X and Y agreement"
    if match = description.match(/between\s+([a-zA-Z\s]+?)\s+and\s+([a-zA-Z\s]+?)(?:\s+on|\s+for|\s+of|$)/i)
      parties << match[1].strip.titleize
      parties << match[2].strip.titleize
    elsif match = description.match(/agreement\s+with\s+([a-zA-Z\s]+?)(?:\s+for|\s+on|$)/i)
      parties << match[1].strip.titleize
    elsif match = description.match(/([a-zA-Z\s]+?)\s+and\s+([a-zA-Z\s]+?)\s+(?:agreement|contract)/i)
      parties << match[1].strip.titleize
      parties << match[2].strip.titleize
    end
    
    # Clean up common words that aren't actually party names
    parties.reject! { |party| 
      %w[service agreement contract collaboration sponsorship employment the a an].include?(party.downcase.strip)
    }
    
    parties.uniq
  end

  def extract_amounts(description)
    amounts = []
    
    # Match various currency patterns
    currency_patterns = [
      /rs\.?\s*(\d+(?:,\d{3})*(?:\.\d{2})?)/i,  # Rs 5000, Rs. 5,000
      /₹\s*(\d+(?:,\d{3})*(?:\.\d{2})?)/,       # ₹5000
      /\$\s*(\d+(?:,\d{3})*(?:\.\d{2})?)/,      # $5000
      /(\d+(?:,\d{3})*(?:\.\d{2})?)\s*(?:rupees|dollars|usd|inr)/i,  # 5000 rupees
      /(?:amount|payment|fee|salary|compensation)\s+of\s+.*?(\d+(?:,\d{3})*(?:\.\d{2})?)/i
    ]
    
    currency_patterns.each do |pattern|
      matches = description.scan(pattern)
      matches.each { |match| amounts << match.is_a?(Array) ? match[0] : match }
    end
    
    amounts.uniq
  end

  def extract_dates(description)
    dates = []
    
    # Date patterns
    date_patterns = [
      /(?:on|from|starting|effective)\s+(today|tomorrow|yesterday)/i,
      /(?:on|from|starting|effective)\s+(\d{1,2}[-\/]\d{1,2}[-\/]\d{2,4})/,
      /(?:on|from|starting|effective)\s+(\d{1,2}\s+(?:january|february|march|april|may|june|july|august|september|october|november|december)\s+\d{2,4})/i,
      /(?:date|dated)\s+(\d{1,2}[-\/]\d{1,2}[-\/]\d{2,4})/i,
      /(january|february|march|april|may|june|july|august|september|october|november|december)\s+\d{1,2},?\s+\d{2,4}/i
    ]
    
    date_patterns.each do |pattern|
      matches = description.scan(pattern)
      matches.each { |match| dates << (match.is_a?(Array) ? match[0] : match) }
    end
    
    # Handle relative dates
    if description.match?(/today/i)
      dates << Date.current.strftime('%B %d, %Y')
    elsif description.match?(/tomorrow/i)
      dates << Date.current.tomorrow.strftime('%B %d, %Y')
    end
    
    dates.uniq
  end

  def extract_contract_keywords(description)
    keywords = []
    
    contract_patterns = {
      'Service Agreement' => /service|consulting|freelance|contractor|work/i,
      'NDA' => /confidential|nda|non-disclosure|secret|proprietary/i,
      'Influencer Agreement' => /influencer|social media|brand collaboration|promotion|marketing/i,
      'Employment Contract' => /employ|job|hiring|salary|position/i,
      'Sponsorship Agreement' => /sponsor|event|partnership/i,
      'Collaboration Agreement' => /collaboration|collab|partner/i,
      'Vendor Agreement' => /vendor|supplier|purchase/i,
      'License Agreement' => /license|intellectual property|software/i
    }
    
    contract_patterns.each do |type, pattern|
      keywords << type if description.match?(pattern)
    end
    
    keywords
  end

  def extract_companies(description)
    companies = []
    
    # Common brand/company patterns
    known_companies = %w[nike adidas google microsoft apple amazon facebook meta twitter linkedin youtube instagram]
    known_companies.each do |company|
      companies << company.titleize if description.match?(/\b#{company}\b/i)
    end
    
    # Pattern for company-like words (capitalized, could be brand names)
    company_matches = description.scan(/\b[A-Z][a-z]*(?:\s+[A-Z][a-z]*)*\b/)
    company_matches.each do |match|
      next if %w[Agreement Contract Service Employment].include?(match)
      companies << match if match.length > 2
    end
    
    companies.uniq
  end

  def extract_locations(description)
    locations = []
    
    # Common locations/jurisdictions
    jurisdictions = %w[india usa us uk canada australia singapore mumbai delhi bangalore hyderabad pune chennai kolkata]
    jurisdictions.each do |location|
      locations << location.titleize if description.match?(/\b#{location}\b/i)
    end
    
    locations.uniq
  end

  def extract_durations(description)
    durations = []
    
    duration_patterns = [
      /(\d+)\s+(?:months?|years?|days?|weeks?)/i,
      /(?:for|duration|term)\s+(?:of\s+)?(\d+\s+(?:months?|years?|days?|weeks?))/i,
      /(one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve)\s+(?:months?|years?)/i
    ]
    
    duration_patterns.each do |pattern|
      matches = description.scan(pattern)
      matches.each { |match| durations << (match.is_a?(Array) ? match[0] : match) }
    end
    
    durations.uniq
  end

  def generate_with_huggingface(description)
    HUGGINGFACE_MODELS.each do |model_url|
      begin
        Rails.logger.info "Trying Hugging Face model: #{model_url}"
        content = call_huggingface_api(description, model_url)
        return content if content.present? && valid_contract_content?(content)
      rescue => e
        Rails.logger.warn "Hugging Face model #{model_url} failed: #{e.message}"
        next
      end
    end
    
    nil
  end

  def call_huggingface_api(description, model_url)
    uri = URI(model_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = @timeout
    http.open_timeout = 30

    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{HUGGINGFACE_API_KEY}"
    request['Content-Type'] = 'application/json'
    request['User-Agent'] = 'ContractGenerator/2.0'

    prompt = build_huggingface_prompt(description)

    request.body = {
      inputs: prompt,
      parameters: {
        max_new_tokens: 2000,
        temperature: 0.7,
        do_sample: true,
        top_p: 0.9,
        repetition_penalty: 1.2,
        return_full_text: false,
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
      Rails.logger.warn "Model is loading, waiting..."
      sleep(20)
      raise "Model is loading"
    else
      Rails.logger.error "Hugging Face API error: #{response.code} - #{response.body}"
      raise "API Error: #{response.code}"
    end
  end

  def build_huggingface_prompt(description)
    contract_type = determine_contract_type(description)
    
    <<~PROMPT
      Draft a comprehensive #{contract_type} for the following requirements:

      Description: #{description}

      Create a complete legal contract with:
      - Title and parties section
      - Detailed scope of work
      - Terms and conditions
      - Payment and timeline
      - Termination clauses
      - Signature section
      - Legal disclaimers

      CONTRACT:

      #{contract_type.upcase}

      This Agreement is entered into on [DATE] between [PARTY_A] ("First Party") and [PARTY_B] ("Second Party").

      WHEREAS, the parties desire to formalize their agreement regarding #{description.downcase};

      NOW, THEREFORE, the parties agree as follows:

      1. SCOPE OF WORK
    PROMPT
  end

  def determine_contract_type(description)
    description_lower = description.to_s.downcase
    
    case description_lower
    when /confidential|nda|non-disclosure|secret|sensitive|proprietary/
      "Non-Disclosure Agreement"
    when /influencer|social media|brand collaboration|promotion|marketing/
      "Influencer Collaboration Agreement"
    when /sponsor|event|partnership/
      "Sponsorship Agreement"
    when /service|consulting|freelance|contractor/
      "Service Agreement"
    when /employ|job|hiring|salary|work/
      "Employment Contract"
    when /gift|product|sample/
      "Gifting Agreement"
    when /vendor|supplier|purchase/
      "Vendor Agreement"
    when /license|intellectual property|software/
      "License Agreement"
    when /lease|rental|property/
      "Lease Agreement"
    when /partnership|joint venture/
      "Partnership Agreement"
    else
      "General Service Agreement"
    end
  end

  def extract_generated_content(result, prompt)
    generated_text = nil

    if result.is_a?(Array) && !result.empty?
      generated_text = result.first.is_a?(Hash) ? 
        (result.first['generated_text'] || result.first['text']) : 
        result.first
    elsif result.is_a?(Hash)
      generated_text = result['generated_text'] || result['text'] || result.dig(0, 'generated_text')
    end

    return nil unless generated_text.present?
    
    # Clean and format the content
    contract_content = clean_and_format_content(generated_text)
    return nil if contract_content.blank?
    
    contract_content
  end

  def clean_and_format_content(content)
    return nil if content.blank?
    
    # Remove any prompt remnants
    content = content.to_s.strip
    
    # Clean up formatting
    content = content
      .gsub(/\r\n/, "\n")
      .gsub(/\n{3,}/, "\n\n")
      .gsub(/^\s+/, '')
      .gsub(/\t/, '    ')
      .strip
    
    # Ensure minimum length
    return nil if content.length < 500
    
    # Basic structure validation
    return nil unless content.match?(/agreement|contract|terms|party|parties/i)
    
    # Add proper contract header if missing
    unless content.match?/^[A-Z\s]+(AGREEMENT|CONTRACT)/
      contract_type = determine_contract_type(@description)
      content = "#{contract_type.upcase}\n\n#{content}"
    end
    
    content
  end

  def valid_contract_content?(content)
    return false if content.blank? || content.length < 500

    # Check for essential contract elements
    essential_elements = [
      /agreement|contract/i,
      /part(y|ies)/i,
      /terms|conditions/i,
      /signature|sign/i
    ]

    essential_elements.all? { |pattern| content.match?(pattern) }
  end

  def format_ai_contract(ai_content)
    formatted_content = ai_content.strip


    # Ensure signature section exists
    unless formatted_content.match?(/signature|sign.*:|witness/i)
      formatted_content += "\n\n#{signature_section}"
    end

    # Add metadata
    formatted_content += "\n\n#{generation_metadata}"
    
    formatted_content.strip
  end

  def generate_intelligent_template
    contract_type = determine_contract_type(@description)
    entities = extract_entities_from_description(@description)
    
    Rails.logger.info "Generating intelligent template for #{contract_type} with entities: #{entities}"
    
    template_content = case contract_type.downcase
    when /non-disclosure|nda|confidential/
      nda_template_enhanced
    when /influencer|social media|brand/
      influencer_template_enhanced
    when /sponsor|partnership/
      sponsorship_template_enhanced
    when /service|consulting|freelance/
      service_template_enhanced
    when /employment|job|hiring/
      employment_template_enhanced
    when /gift|product/
      gifting_template_enhanced
    when /vendor|supplier/
      vendor_template_enhanced
    else
      general_template_enhanced
    end
    
    # Personalize template with extracted entities
    personalize_template_with_entities(template_content, entities)
  end

  def personalize_template_with_entities(template, entities)
    personalized = template.dup
    
    # Replace party placeholders with extracted names
    if entities[:parties]&.any?
      party_a = entities[:parties][0]
      party_b = entities[:parties][1] if entities[:parties].size > 1
      
      personalized.gsub!(/\[PARTY_A\]|\[FIRST_PARTY\]|\[COMPANY_NAME\]/, party_a) if party_a
      personalized.gsub!(/\[PARTY_B\]|\[SECOND_PARTY\]|\[CLIENT_NAME\]|\[INFLUENCER_NAME\]/, party_b) if party_b
    end
    
    # Replace amount placeholders
    if entities[:amounts]&.any?
      amount = entities[:amounts].first
      currency = amount.match?(/rs|₹|rupees/i) ? 'Rs' : '$'
      personalized.gsub!(/\[AMOUNT\]|\[PAYMENT_AMOUNT\]|\[COMPENSATION\]/, "#{currency} #{amount}")
    end
    
    # Replace date placeholders
    if entities[:dates]&.any?
      date = entities[:dates].first
      personalized.gsub!(/\[DATE\]|\[EFFECTIVE_DATE\]|\[AGREEMENT_DATE\]/, date)
    end
    
    # Replace location/jurisdiction placeholders
    if entities[:locations]&.any?
      location = entities[:locations].first
      personalized.gsub!(/\[JURISDICTION\]|\[GOVERNING_LAW\]/, "the laws of #{location}")
      personalized.gsub!(/\[LOCATION\]|\[CITY\]/, location)
    end
    
    # Replace company/brand specific placeholders
    if entities[:companies]&.any?
      company = entities[:companies].first
      personalized.gsub!(/\[BRAND_NAME\]|\[COMPANY\]/, company)
    end
    
    # Replace duration placeholders
    if entities[:durations]&.any?
      duration = entities[:durations].first
      personalized.gsub!(/\[TERM\]|\[DURATION\]|\[CONTRACT_PERIOD\]/, duration)
    end
    
    # If no specific date was provided but "today" was mentioned, use current date
    if @description.match?(/today/i) && !entities[:dates]&.any?
      current_date = Date.current.strftime('%B %d, %Y')
      personalized.gsub!(/\[DATE\]|\[EFFECTIVE_DATE\]|\[AGREEMENT_DATE\]/, current_date)
    end
    
    personalized
  end

  def nda_template_enhanced
    <<~TEMPLATE
      NON-DISCLOSURE AGREEMENT

      This Non-Disclosure Agreement ("Agreement") is entered into as of [DATE] by and between:

      [DISCLOSING_PARTY_NAME], a [ENTITY_TYPE] with its principal place of business at [ADDRESS] ("Disclosing Party")

      AND

      [RECEIVING_PARTY_NAME], a [ENTITY_TYPE] with its principal place of business at [ADDRESS] ("Receiving Party")

      RECITALS

      WHEREAS, the Disclosing Party possesses certain confidential and proprietary information related to #{@description};

      WHEREAS, the Receiving Party desires to receive such confidential information for the purpose of [PURPOSE];

      WHEREAS, the parties wish to protect the confidentiality of such information;

      NOW, THEREFORE, in consideration of the mutual covenants contained herein, the parties agree as follows:

      1. DEFINITION OF CONFIDENTIAL INFORMATION
         "Confidential Information" means all non-public, proprietary, or confidential information disclosed by the Disclosing Party, including but not limited to:
         a) Technical data, source code, algorithms, and software
         b) Business plans, strategies, and financial information
         c) Customer lists and supplier information
         d) Marketing strategies and pricing information
         e) Any information marked as "Confidential" or that would reasonably be considered confidential

      2. OBLIGATIONS OF RECEIVING PARTY
         The Receiving Party agrees to:
         a) Hold all Confidential Information in strict confidence
         b) Not disclose Confidential Information to third parties without written consent
         c) Use Confidential Information solely for the agreed purpose
         d) Take reasonable security measures to protect Confidential Information
         e) Not reverse engineer or attempt to derive the composition of Confidential Information

      3. EXCEPTIONS
         The obligations herein shall not apply to information that:
         a) Is or becomes publicly available through no breach of this Agreement
         b) Was rightfully known prior to disclosure
         c) Is rightfully received from a third party without confidentiality restrictions
         d) Is required to be disclosed by law or court order

      4. RETURN OF INFORMATION
         Upon termination or written request, the Receiving Party shall promptly return or destroy all Confidential Information and certify such destruction in writing.

      5. TERM AND TERMINATION
         This Agreement shall remain in effect for [TERM] years from the date of execution, unless terminated earlier. The obligations of confidentiality shall survive termination for [SURVIVAL_PERIOD] years.

      6. REMEDIES
         The Receiving Party acknowledges that breach of this Agreement would cause irreparable harm, and the Disclosing Party shall be entitled to injunctive relief and monetary damages.

      7. GOVERNING LAW
         This Agreement shall be governed by the laws of [JURISDICTION] without regard to conflict of laws principles.

      8. ENTIRE AGREEMENT
         This Agreement constitutes the entire agreement between the parties and supersedes all prior negotiations and agreements relating to the subject matter hereof.

      #{signature_section}

      #{generation_metadata}
    TEMPLATE
  end

  def influencer_template_enhanced
    <<~TEMPLATE
      INFLUENCER COLLABORATION AGREEMENT

      This Influencer Collaboration Agreement ("Agreement") is entered into as of [DATE] between:

      [BRAND_NAME], a [ENTITY_TYPE] with its principal place of business at [BRAND_ADDRESS] ("Brand")

      AND

      [INFLUENCER_NAME], an individual with principal residence at [INFLUENCER_ADDRESS] ("Influencer")

      RECITALS

      WHEREAS, Brand desires to engage Influencer to promote its products and services through digital content creation;

      WHEREAS, Influencer has expertise in content creation and social media marketing;

      WHEREAS, the parties wish to formalize their collaboration regarding #{@description};

      NOW, THEREFORE, the parties agree as follows:

      1. CAMPAIGN DETAILS
         a) Campaign Description: #{@description}
         b) Campaign Duration: [START_DATE] to [END_DATE]
         c) Target Platforms: [SOCIAL_MEDIA_PLATFORMS]
         d) Content Types: [CONTENT_TYPES]

      2. SCOPE OF WORK
         Influencer shall create and publish:
         a) [NUMBER] high-quality posts featuring Brand's products
         b) [NUMBER] stories with Brand mentions
         c) [NUMBER] video content pieces
         d) [OTHER_DELIVERABLES]

      3. CONTENT REQUIREMENTS
         a) All content must be original, authentic, and align with Brand's values
         b) Content must comply with platform guidelines and applicable laws
         c) Proper FTC disclosure hashtags must be used (#ad, #sponsored, #partnership)
         d) Content requires Brand's pre-approval before publication
         e) Content must meet professional quality standards
         f) Content must be published within agreed timeframes

      4. COMPENSATION
         a) Total Fee: [CURRENCY] [AMOUNT]
         b) Payment Schedule: [PAYMENT_TERMS]
         c) Additional Compensation: [PRODUCTS/SERVICES]
         d) Performance Bonuses: [BONUS_TERMS]
         e) Expenses: [EXPENSE_TERMS]

      5. INTELLECTUAL PROPERTY RIGHTS
         a) Influencer retains ownership of original creative content
         b) Brand receives non-exclusive, perpetual license to use content for marketing
         c) Brand may cross-post content with proper attribution
         d) Influencer grants Brand right to use their name and likeness in connection with campaign

      6. PERFORMANCE METRICS
         a) Minimum reach: [REACH_REQUIREMENTS]
         b) Engagement targets: [ENGAGEMENT_TARGETS]
         c) Reporting requirements: [REPORTING_SCHEDULE]

      7. COMPLIANCE AND LEGAL
         a) All content must comply with FTC guidelines and local advertising laws
         b) Influencer must disclose material connections to Brand
         c) Content must not violate any third-party rights
         d) Both parties must comply with platform terms of service

      8. EXCLUSIVITY
         During the campaign period, Influencer shall not promote direct competitors without written consent.

      9. TERMINATION
         Either party may terminate with [NOTICE_PERIOD] days written notice. Upon termination, all committed deliverables must be completed.

      10. CONFIDENTIALITY
          Both parties agree to maintain confidentiality of proprietary information and campaign details.

      11. FORCE MAJEURE
          Neither party shall be liable for delays due to circumstances beyond reasonable control.

      12. GOVERNING LAW
          This Agreement shall be governed by the laws of [JURISDICTION].

      #{signature_section}

      #{generation_metadata}
    TEMPLATE
  end

  def service_template_enhanced
    <<~TEMPLATE
      SERVICE AGREEMENT

      This Service Agreement ("Agreement") is entered into as of [DATE] between:

      [CLIENT_NAME], a [ENTITY_TYPE] with its principal place of business at [CLIENT_ADDRESS] ("Client")

      AND

      [SERVICE_PROVIDER_NAME], a [ENTITY_TYPE] with its principal place of business at [PROVIDER_ADDRESS] ("Service Provider")

      RECITALS

      WHEREAS, Client desires to engage Service Provider to provide certain services;

      WHEREAS, Service Provider has the expertise and capability to provide such services;

      WHEREAS, the parties wish to formalize their agreement regarding #{@description};

      NOW, THEREFORE, the parties agree as follows:

      1. SCOPE OF SERVICES
         Service Provider shall provide the following services:
         a) [DETAILED_SERVICE_DESCRIPTION]
         b) [SPECIFIC_DELIVERABLES]
         c) [PERFORMANCE_STANDARDS]
         d) [QUALITY_REQUIREMENTS]

      2. TERM AND TIMELINE
         a) Service Commencement: [START_DATE]
         b) Service Completion: [END_DATE]
         c) Key Milestones: [MILESTONE_SCHEDULE]
         d) Progress Reporting: [REPORTING_SCHEDULE]

      3. COMPENSATION
         a) Total Service Fee: [CURRENCY] [AMOUNT]
         b) Payment Schedule: [PAYMENT_TERMS]
         c) Additional Costs: [EXPENSE_TERMS]
         d) Late Payment Penalties: [PENALTY_TERMS]
         e) Taxes: [TAX_RESPONSIBILITIES]

      4. CLIENT OBLIGATIONS
         Client shall:
         a) Provide necessary information, materials, and access
         b) Provide timely feedback and approvals
         c) Make payments according to agreed terms
         d) Cooperate in good faith for project success

      5. SERVICE PROVIDER OBLIGATIONS
         Service Provider shall:
         a) Perform services with professional skill and care
         b) Meet all agreed deadlines and specifications
         c) Maintain confidentiality of Client information
         d) Comply with all applicable laws and regulations
         e) Provide regular status updates

      6. INTELLECTUAL PROPERTY
         a) Work product created specifically for Client shall belong to Client
         b) Service Provider's pre-existing IP remains with Service Provider
         c) Client grants necessary licenses for Service Provider to perform services
         d) Both parties warrant they have rights to use their respective IP

      7. CONFIDENTIALITY
         Both parties agree to maintain strict confidentiality of proprietary information received during the engagement.

      8. WARRANTIES AND REPRESENTATIONS
         a) Service Provider warrants services will be performed in workmanlike manner
         b) Both parties warrant they have authority to enter this Agreement
         c) Services will comply with applicable laws and industry standards

      9. LIMITATION OF LIABILITY
         Service Provider's liability shall be limited to the total amount paid under this Agreement.

      10. TERMINATION
          Either party may terminate with [NOTICE_PERIOD] days written notice. Client shall pay for services rendered through termination date.

      11. FORCE MAJEURE
          Neither party shall be liable for delays due to circumstances beyond reasonable control.

      12. GOVERNING LAW
          This Agreement shall be governed by the laws of [JURISDICTION].

      #{signature_section}

      #{generation_metadata}
    TEMPLATE
  end

  def employment_template_enhanced
    <<~TEMPLATE
      EMPLOYMENT AGREEMENT

      This Employment Agreement ("Agreement") is entered into as of [DATE] between:

      [COMPANY_NAME], a [ENTITY_TYPE] with its principal place of business at [COMPANY_ADDRESS] ("Company")

      AND

      [EMPLOYEE_NAME], an individual with residence at [EMPLOYEE_ADDRESS] ("Employee")

      RECITALS

      WHEREAS, Company desires to employ Employee in the capacity described herein;

      WHEREAS, Employee desires to accept such employment subject to the terms and conditions set forth herein;

      WHEREAS, the parties wish to formalize their employment relationship regarding #{@description};

      NOW, THEREFORE, the parties agree as follows:

      1. EMPLOYMENT
         a) Position: [JOB_TITLE]
         b) Department: [DEPARTMENT]
         c) Reporting Structure: [REPORTING_MANAGER]
         d) Employment Type: [FULL_TIME/PART_TIME/CONTRACT]
         e) Start Date: [START_DATE]

      2. DUTIES AND RESPONSIBILITIES
         Employee shall:
         a) [PRIMARY_RESPONSIBILITIES]
         b) [SECONDARY_RESPONSIBILITIES]
         c) Perform duties in accordance with Company policies
         d) Maintain professional conduct and standards
         e) Participate in training and development programs

      3. COMPENSATION
         a) Base Salary: [CURRENCY] [AMOUNT] per [PERIOD]
         b) Bonus Eligibility: [BONUS_STRUCTURE]
         c) Benefits: [BENEFIT_PACKAGE]
         d) Equity/Stock Options: [EQUITY_TERMS]
         e) Performance Reviews: [REVIEW_SCHEDULE]

      4. WORKING CONDITIONS
         a) Work Schedule: [WORKING_HOURS]
         b) Work Location: [WORK_LOCATION]
         c) Remote Work Policy: [REMOTE_WORK_TERMS]
         d) Vacation/PTO: [VACATION_POLICY]
         e) Sick Leave: [SICK_LEAVE_POLICY]

      5. CONFIDENTIALITY
         Employee agrees to maintain strict confidentiality of Company's proprietary information and trade secrets.

      6. INTELLECTUAL PROPERTY
         All work product created by Employee during employment shall be the exclusive property of Company.

      7. NON-COMPETITION
         Employee agrees not to engage in competing activities during employment and for [PERIOD] after termination.

      8. TERMINATION
         a) Either party may terminate with [NOTICE_PERIOD] notice
         b) Company may terminate immediately for cause
         c) Employee entitled to [SEVERANCE_TERMS] upon certain terminations

      9. COMPLIANCE
         Employee shall comply with all Company policies, procedures, and applicable laws.

      10. GOVERNING LAW
          This Agreement shall be governed by the laws of [JURISDICTION].

      #{signature_section}

      #{generation_metadata}
    TEMPLATE
  end

  def sponsorship_template_enhanced
    <<~TEMPLATE
      SPONSORSHIP AGREEMENT

      This Sponsorship Agreement ("Agreement") is entered into as of [DATE] between:

      [SPONSOR_NAME], a [ENTITY_TYPE] with its principal place of business at [SPONSOR_ADDRESS] ("Sponsor")

      AND

      [SPONSORED_PARTY_NAME], a [ENTITY_TYPE] with its principal place of business at [SPONSORED_ADDRESS] ("Sponsored Party")

      RECITALS

      WHEREAS, Sponsored Party is organizing/participating in [EVENT/ACTIVITY];

      WHEREAS, Sponsor desires to support and gain marketing benefits from such association;

      WHEREAS, the parties wish to formalize their sponsorship relationship regarding #{@description};

      NOW, THEREFORE, the parties agree as follows:

      1. SPONSORSHIP DETAILS
         a) Event/Activity: [EVENT_NAME]
         b) Date(s): [EVENT_DATES]
         c) Location: [EVENT_LOCATION]
         d) Sponsorship Level: [SPONSORSHIP_TIER]
         e) Exclusive Rights: [EXCLUSIVITY_TERMS]

      2. SPONSOR BENEFITS
         Sponsor shall receive:
         a) [NAMING_RIGHTS]
         b) [LOGO_PLACEMENT]
         c) [MARKETING_OPPORTUNITIES]
         d) [HOSPITALITY_BENEFITS]
         e) [MEDIA_COVERAGE]
         f) [PROMOTIONAL_MATERIALS]

      3. SPONSORSHIP INVESTMENT
         a) Cash Contribution: [CURRENCY] [AMOUNT]
         b) In-Kind Contribution: [IN_KIND_VALUE]
         c) Payment Schedule: [PAYMENT_TERMS]
         d) Additional Costs: [ADDITIONAL_EXPENSES]

      4. SPONSORED PARTY OBLIGATIONS
         Sponsored Party shall:
         a) Provide agreed marketing benefits to Sponsor
         b) Use sponsor materials according to brand guidelines
         c) Maintain professional standards during event
         d) Provide post-event reporting and metrics
         e) Acknowledge Sponsor in all appropriate communications

      5. MARKETING AND PROMOTION
         a) Both parties may promote the partnership
         b) All marketing materials require mutual approval
         c) Sponsor logo usage guidelines must be followed
         d) Social media promotion requirements: [SOCIAL_MEDIA_TERMS]

      6. INTELLECTUAL PROPERTY
         a) Each party retains ownership of their respective trademarks
         b) Limited license granted for promotional purposes
         c) No rights granted beyond scope of this Agreement

      7. FORCE MAJEURE
         If event is cancelled due to circumstances beyond control, parties will negotiate alternative arrangements.

      8. TERMINATION
         Either party may terminate with [NOTICE_PERIOD] days written notice.

      9. GOVERNING LAW
         This Agreement shall be governed by the laws of [JURISDICTION].

      #{signature_section}

      #{generation_metadata}
    TEMPLATE
  end

  def gifting_template_enhanced
    <<~TEMPLATE
      GIFTING AGREEMENT

      This Gifting Agreement ("Agreement") is entered into as of [DATE] between:

      [GIFTING_PARTY_NAME], a [ENTITY_TYPE] with its principal place of business at [GIFTING_ADDRESS] ("Gifting Party")

      AND

      [RECIPIENT_NAME], an individual/entity with address at [RECIPIENT_ADDRESS] ("Recipient")

      RECITALS

      WHEREAS, Gifting Party desires to provide certain products or services to Recipient;

      WHEREAS, Recipient agrees to receive such gifts subject to the terms herein;

      WHEREAS, the parties wish to formalize their gifting arrangement regarding #{@description};

      NOW, THEREFORE, the parties agree as follows:

      1. GIFT DETAILS
         a) Products/Services: [GIFT_DESCRIPTION]
         b) Estimated Value: [CURRENCY] [VALUE]
         c) Delivery Terms: [DELIVERY_SCHEDULE]
         d) Shipping/Handling: [SHIPPING_TERMS]

      2. RECIPIENT OBLIGATIONS
         Recipient agrees to:
         a) [USAGE_REQUIREMENTS]
         b) [SOCIAL_MEDIA_OBLIGATIONS]
         c) [FEEDBACK_REQUIREMENTS]
         d) [COMPLIANCE_OBLIGATIONS]

      3. DISCLOSURE REQUIREMENTS
         a) Recipient must disclose gift relationship in content
         b) Appropriate hashtags must be used (#gift, #gifted, #pr)
         c) Compliance with FTC guidelines and local laws
         d) Honest and authentic representation of products

      4. CONTENT CREATION
         a) Content Requirements: [CONTENT_SPECIFICATIONS]
         b) Posting Schedule: [POSTING_TIMELINE]
         c) Approval Process: [APPROVAL_REQUIREMENTS]
         d) Usage Rights: [CONTENT_USAGE_RIGHTS]

      5. INTELLECTUAL PROPERTY
         a) Recipient retains ownership of original content
         b) Gifting Party receives license to use content for marketing
         c) Brand trademark usage guidelines apply

      6. NO GUARANTEED PROMOTION
         This is a gift with no guarantee of promotion or endorsement.

      7. TERMINATION
         Either party may terminate this arrangement with written notice.

      8. GOVERNING LAW
         This Agreement shall be governed by the laws of [JURISDICTION].

      #{signature_section}

      #{generation_metadata}
    TEMPLATE
  end

  def vendor_template_enhanced
    <<~TEMPLATE
      VENDOR AGREEMENT

      This Vendor Agreement ("Agreement") is entered into as of [DATE] between:

      [BUYER_NAME], a [ENTITY_TYPE] with its principal place of business at [BUYER_ADDRESS] ("Buyer")

      AND

      [VENDOR_NAME], a [ENTITY_TYPE] with its principal place of business at [VENDOR_ADDRESS] ("Vendor")

      RECITALS

      WHEREAS, Buyer desires to purchase certain goods/services from Vendor;

      WHEREAS, Vendor agrees to supply such goods/services subject to the terms herein;

      WHEREAS, the parties wish to formalize their commercial relationship regarding #{@description};

      NOW, THEREFORE, the parties agree as follows:

      1. SCOPE OF SUPPLY
         Vendor shall supply:
         a) [PRODUCTS/SERVICES_DESCRIPTION]
         b) [SPECIFICATIONS]
         c) [QUALITY_STANDARDS]
         d) [DELIVERY_REQUIREMENTS]

      2. PRICING AND PAYMENT
         a) Pricing: [PRICING_STRUCTURE]
         b) Payment Terms: [PAYMENT_SCHEDULE]
         c) Currency: [CURRENCY]
         d) Late Payment Charges: [LATE_FEES]
         e) Taxes: [TAX_RESPONSIBILITIES]

      3. DELIVERY TERMS
         a) Delivery Schedule: [DELIVERY_TIMELINE]
         b) Delivery Location: [DELIVERY_ADDRESS]
         c) Shipping Terms: [INCOTERMS]
         d) Risk of Loss: [RISK_ALLOCATION]

      4. QUALITY ASSURANCE
         a) All products must meet specified quality standards
         b) Inspection and acceptance procedures
         c) Warranty terms: [WARRANTY_PERIOD]
         d) Return/replacement policy

      5. VENDOR OBLIGATIONS
         Vendor shall:
         a) Maintain appropriate insurance coverage
         b) Comply with all applicable laws and regulations
         c) Maintain quality certifications as required
         d) Provide timely delivery and communication

      6. BUYER OBLIGATIONS
         Buyer shall:
         a) Provide accurate specifications and requirements
         b) Make payments according to agreed terms
         c) Provide reasonable access for delivery
         d) Inspect goods upon receipt

      7. INTELLECTUAL PROPERTY
         Both parties warrant they have rights to use their respective IP in connection with this Agreement.

      8. CONFIDENTIALITY
         Both parties agree to maintain confidentiality of proprietary information.

      9. TERMINATION
         Either party may terminate with [NOTICE_PERIOD] days written notice.

      10. GOVERNING LAW
          This Agreement shall be governed by the laws of [JURISDICTION].

      #{signature_section}

      #{generation_metadata}
    TEMPLATE
  end

  def general_template_enhanced
    <<~TEMPLATE
      GENERAL AGREEMENT

      This Agreement ("Agreement") is entered into as of [DATE] between:

      [PARTY_A_NAME], a [ENTITY_TYPE] with its principal place of business at [PARTY_A_ADDRESS] ("Party A")

      AND

      [PARTY_B_NAME], a [ENTITY_TYPE] with its principal place of business at [PARTY_B_ADDRESS] ("Party B")

      RECITALS

      WHEREAS, the parties desire to enter into an agreement regarding #{@description};

      WHEREAS, both parties have the authority and capacity to enter into this Agreement;

      NOW, THEREFORE, the parties agree as follows:

      1. SCOPE AND PURPOSE
         This Agreement governs the relationship between the parties regarding [AGREEMENT_PURPOSE].

      2. TERMS AND CONDITIONS
         a) [SPECIFIC_TERMS]
         b) [OBLIGATIONS_PARTY_A]
         c) [OBLIGATIONS_PARTY_B]
         d) [PERFORMANCE_STANDARDS]

      3. CONSIDERATION
         a) Compensation/Exchange: [CONSIDERATION_TERMS]
         b) Payment Schedule: [PAYMENT_TERMS]
         c) Additional Costs: [EXPENSE_ALLOCATION]

      4. TERM AND TERMINATION
         a) Term: [AGREEMENT_DURATION]
         b) Termination: [TERMINATION_CONDITIONS]
         c) Post-termination obligations: [POST_TERMINATION_TERMS]

      5. INTELLECTUAL PROPERTY
         [INTELLECTUAL_PROPERTY_TERMS]

      6. CONFIDENTIALITY
         Both parties agree to maintain confidentiality of proprietary information.

      7. WARRANTIES AND REPRESENTATIONS
         Each party warrants they have authority to enter this Agreement.

      8. LIMITATION OF LIABILITY
         [LIABILITY_LIMITATION_TERMS]

      9. FORCE MAJEURE
         Neither party shall be liable for delays due to circumstances beyond reasonable control.

      10. GOVERNING LAW
          This Agreement shall be governed by the laws of [JURISDICTION].

      #{signature_section}

      #{generation_metadata}
    TEMPLATE
  end

  def signature_section
    <<~SIGNATURE
      SIGNATURE SECTION

      IN WITNESS WHEREOF, the parties have executed this Agreement as of the date first written above.

      PARTY A:                                    PARTY B:

      ________________________________           ________________________________
      Signature                                  Signature

      ________________________________           ________________________________
      Print Name: [PARTY_A_SIGNATORY]           Print Name: [PARTY_B_SIGNATORY]

      ________________________________           ________________________________
      Title: [PARTY_A_TITLE]                    Title: [PARTY_B_TITLE]

      ________________________________           ________________________________
      Date: [DATE]                              Date: [DATE]

      WITNESSES:

      Witness 1:                                 Witness 2:

      ________________________________           ________________________________
      Signature                                  Signature

      ________________________________           ________________________________
      Print Name: [WITNESS_1_NAME]              Print Name: [WITNESS_2_NAME]

      ________________________________           ________________________________
      Address: [WITNESS_1_ADDRESS]              Address: [WITNESS_2_ADDRESS]

      ________________________________           ________________________________
      Date: [DATE]                              Date: [DATE]
    SIGNATURE
  end

  def generation_metadata
    <<~METADATA
      ═══════════════════════════════════════════════════════════════════════════════════════
      CONTRACT GENERATION INFORMATION
      ═══════════════════════════════════════════════════════════════════════════════════════
      Generated: #{Time.current.strftime('%B %d, %Y at %I:%M %p %Z')}
      Method: AI-Powered Contract Generation
      Description: #{@description.to_s.truncate(200)}
      Contract Type: #{determine_contract_type(@description)}
      
      IMPORTANT LEGAL NOTICES:
      ═══════════════════════════════════════════════════════════════════════════════════════
      ⚠️  DRAFT DOCUMENT: This contract is a draft and must be reviewed by qualified legal counsel
      ⚠️  CUSTOMIZATION REQUIRED: All placeholder values [IN BRACKETS] must be completed
      ⚠️  JURISDICTION: Ensure governing law clause matches your jurisdiction
      ⚠️  COMPLIANCE: Verify compliance with local laws and regulations
      ⚠️  PROFESSIONAL REVIEW: Seek professional legal advice before execution
      
      DISCLAIMER:
      This contract was generated by AI and is provided for informational purposes only. 
      It does not constitute legal advice and should not be used without proper legal review.
      The accuracy and completeness of this document is not guaranteed.
      
      For legal advice, consult with a qualified attorney in your jurisdiction.
      ═══════════════════════════════════════════════════════════════════════════════════════
    METADATA
  end
end