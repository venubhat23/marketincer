class AiContractGenerationService
  require 'openai'
  require 'net/http'
  require 'json'
  
  # Primary AI service configuration
  OPENAI_API_KEY = Rails.application.credentials.openai_api_key || ENV['OPENAI_API_KEY']
  
  # Simple fallback responses for common contract types
  FALLBACK_TEMPLATES = {
    'collaboration' => 'COLLABORATION AGREEMENT',
    'partnership' => 'PARTNERSHIP AGREEMENT',
    'service' => 'SERVICE AGREEMENT',
    'employment' => 'EMPLOYMENT AGREEMENT',
    'nda' => 'NON-DISCLOSURE AGREEMENT',
    'default' => 'CONTRACT AGREEMENT'
  }.freeze

  def initialize(description)
    @description = description
    @timeout = 30
    @max_retries = 2
    @openai_client = setup_openai_client if OPENAI_API_KEY.present?
  end

  def generate
    retries = 0

    begin
      Rails.logger.info "AI generation started for: #{@description}"
      
      # Try OpenAI first
      if @openai_client
        Rails.logger.info "Attempting OpenAI generation"
        ai_response = generate_with_openai
        
        if ai_response.present? && ai_response.length > 100
          Rails.logger.info "OpenAI generation successful: #{ai_response.length} chars"
          return ai_response
        else
          Rails.logger.warn "OpenAI generation failed or too short response"
        end
      else
        Rails.logger.warn "OpenAI client not available, API key: #{OPENAI_API_KEY.present? ? 'present' : 'missing'}"
      end

      # Use simple template-based generation as fallback
      Rails.logger.info "Using template-based generation as fallback"
      ai_response = generate_with_template
      
      if ai_response.present?
        Rails.logger.info "Template generation successful: #{ai_response.length} chars"
        return ai_response
      end

      # Final fallback
      Rails.logger.warn "All generation methods failed, returning basic template"
      return generate_basic_contract
      
    rescue => e
      retries += 1
      if retries <= @max_retries
        Rails.logger.warn "AI generation attempt #{retries} failed: #{e.message}. Retrying..."
        sleep(1)
        retry
      else
        Rails.logger.error "AI generation failed after #{@max_retries} attempts: #{e.message}"
        return generate_basic_contract
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

  def generate_with_openai
    return nil unless @openai_client

    Rails.logger.info "Making OpenAI API call..."
    
    # Create a proper contract generation prompt
    prompt = build_contract_prompt(@description)
    
    response = @openai_client.chat(
      parameters: {
        model: 'gpt-3.5-turbo',
        messages: [
          {
            role: "system",
            content: "You are a professional contract lawyer. Generate a complete, legally sound contract based on the user's description. The contract should be detailed, professional, and include all necessary clauses."
          },
          {
            role: "user", 
            content: prompt
          }
        ],
        max_tokens: 2000,
        temperature: 0.7
      }
    )

    if response.dig("choices", 0, "message", "content")
      ai_response = response["choices"][0]["message"]["content"]
      Rails.logger.info "OpenAI API response received: #{ai_response.length} characters"
      return ai_response.strip
    else
      Rails.logger.error "OpenAI API response format unexpected: #{response.inspect}"
      return nil
    end
    
  rescue OpenAI::Error => e
    Rails.logger.error "OpenAI API error: #{e.message}"
    return nil
  rescue => e
    Rails.logger.error "OpenAI API call failed: #{e.message}"
    return nil
  end

  def generate_with_template
    # Analyze the description to determine contract type
    contract_type = determine_contract_type(@description)
    
    # Generate a contract based on the description and type
    case contract_type
    when 'collaboration'
      generate_collaboration_contract
    when 'partnership'
      generate_partnership_contract
    when 'service'
      generate_service_contract
    when 'employment'
      generate_employment_contract
    when 'nda'
      generate_nda_contract
    else
      generate_basic_contract
    end
  end

  def build_contract_prompt(description)
    "Please generate a professional contract based on the following description: #{description}. 
    
    The contract should include:
    - Proper legal structure with parties, scope, terms, and conditions
    - Clear deliverables and timelines if applicable
    - Payment terms if mentioned
    - Proper legal clauses for termination, confidentiality, and governing law
    - Professional formatting with sections and subsections
    
    Make sure the contract is complete and ready to use."
  end

  def determine_contract_type(description)
    desc_lower = description.downcase
    
    return 'collaboration' if desc_lower.include?('collaboration') || desc_lower.include?('collab')
    return 'partnership' if desc_lower.include?('partnership') || desc_lower.include?('partner')
    return 'service' if desc_lower.include?('service') || desc_lower.include?('work')
    return 'employment' if desc_lower.include?('employment') || desc_lower.include?('job')
    return 'nda' if desc_lower.include?('nda') || desc_lower.include?('non-disclosure')
    
    'default'
  end

  def generate_collaboration_contract
    # Extract key information from description
    entities = extract_entities(@description)
    
    <<~CONTRACT
      **COLLABORATION AGREEMENT**

      This Collaboration Agreement ("Agreement") is made and entered into on **[Date]**, by and between:

      **#{entities[:party1] || '[Party 1]'}**, #{entities[:party1_type] || 'having its principal place of business at [Address]'}, hereinafter referred to as the "Brand",

      **AND**

      **#{entities[:party2] || '[Party 2]'}**, #{entities[:party2_type] || 'an individual content creator, residing at [Address]'}, hereinafter referred to as the "Influencer".

      Collectively referred to as the "Parties".

      ---

      ### 1. **Scope of Collaboration**

      #{generate_scope_section(entities)}

      ### 2. **Deliverables**

      #{generate_deliverables_section(entities)}

      ### 3. **Compensation**

      #{generate_compensation_section(entities)}

      ### 4. **Timeline**

      #{generate_timeline_section(entities)}

      ### 5. **Content Rights and Usage**

      * The Influencer grants the Brand a **non-exclusive, royalty-free license** to use, repost, and promote the content across digital channels.
      * The Brand may not alter the content without the Influencer's prior consent.

      ### 6. **Disclosure and Compliance**

      * Influencer shall clearly disclose the collaboration in all posts in compliance with applicable guidelines using hashtags such as **#Ad**, **#Sponsored**, or as applicable.

      ### 7. **Confidentiality**

      * Both Parties agree to keep the terms of this Agreement confidential unless disclosure is required by law.

      ### 8. **Termination**

      * Either party may terminate this Agreement with written notice if the other party breaches any material term and fails to remedy within 3 business days.

      ### 9. **Governing Law**

      * This Agreement shall be governed by the laws of **[Applicable Jurisdiction]**.

      ---

      **IN WITNESS WHEREOF**, the Parties hereto have executed this Agreement on the date first written above.

      ---

      **For #{entities[:party1] || '[Party 1]'}**
      Name: ________________
      Title: ________________
      Signature: ________________
      Date: ________________

      **For #{entities[:party2] || '[Party 2]'}**
      Name: ________________
      Signature: ________________
      Date: ________________

      ---

      This contract has been generated based on your description: "#{@description}"
    CONTRACT
  end

  def generate_basic_contract
    <<~CONTRACT
      **CONTRACT AGREEMENT**

      This Agreement is made and entered into on **[Date]**, by and between the parties described below.

      **Description:** #{@description}

      ### 1. **Parties**
      * Party 1: [Name and Address]
      * Party 2: [Name and Address]

      ### 2. **Scope of Work**
      Based on your description: #{@description}

      ### 3. **Terms and Conditions**
      * Duration: As specified in the description
      * Payment: As specified in the description
      * Deliverables: As specified in the description

      ### 4. **Legal Provisions**
      * **Governing Law:** This Agreement shall be governed by applicable laws.
      * **Termination:** Either party may terminate with appropriate notice.
      * **Confidentiality:** Both parties agree to maintain confidentiality of sensitive information.

      ### 5. **Signatures**
      
      **Party 1:**
      Name: ________________
      Signature: ________________
      Date: ________________

      **Party 2:**
      Name: ________________
      Signature: ________________
      Date: ________________

      ---
      
      This contract has been generated based on your description. Please customize the specific terms, names, and legal provisions as needed for your situation.
    CONTRACT
  end

  def extract_entities(description)
    entities = {}
    
    # Try to extract parties, amounts, timeframes, etc.
    # This is a simple extraction - can be enhanced
    
    # Extract potential party names (proper nouns and common brand names)
    words = description.split
    proper_nouns = words.select { |word| word =~ /^[A-Z][a-z]+/ }
    
    # Also look for common brand names that might be lowercase
    brand_names = words.select { |word| word.downcase =~ /^(adidas|nike|apple|google|microsoft|amazon|facebook|twitter|instagram|youtube|tiktok|snapchat|linkedin|uber|airbnb|tesla|netflix|spotify|zoom|slack|discord|whatsapp|telegram|samsung|sony|lg|hp|dell|intel|amd|nvidia|oracle|salesforce|adobe|vmware|cisco|ibm|redhat|mongodb|shopify|stripe|paypal|square|twilio|okta|snowflake|databricks|palantir|crowdstrike|zscaler|cloudflare|fastly|newrelic|splunk|elastic|atlassian|jira|confluence|trello|asana|monday|notion|figma|sketch|canva|wix|squarespace|wordpress|drupal|magento|prestashop|bigcommerce|etsy|ebay|walmart|target|costco|homedepot|lowes|bestbuy|gamestop|barnes|starbucks|mcdonalds|burgerking|subway|pizzahut|dominos|kfc|tacobell|chipotle|dunkindonuts|baskinrobbins|dairyqueen|wendys|arbys|sonic|jackinthebox|carlsjr|whitecastle|fiveguys|shakeshack|innout|chilis|applebees|olivegarden|redlobster|outback|texasroadhouse|fridaytgi|dennys|ihop|cracker|panera|buffalowildwings|hooters|tilted|davebusters|chucke|peter|rainforest|hardrock|planetholly|espn|disney|universal|sixflags|cedar|knotts|busch|seaworld|legoland|madame|ripley|guinness|national|smithsonian|metropolitan|moma|guggenheim|whitney|brooklyn|chicago|detroit|philadelphia|phoenix|seattle|portland|denver|miami|orlando|vegas|angeles|francisco|diego|jose|austin|dallas|houston|antonio|charlotte|raleigh|atlanta|tampa|jacksonville|nashville|memphis|louis|kansas|cleveland|cincinnati|milwaukee|minneapolis|indianapolis|columbus|pittsburgh|baltimore|washington|boston|newark|buffalo|rochester|syracuse|albany|hartford|providence|manchester|burlington|portland|augusta|concord|montpelier|boston|springfield|worcester|lowell|cambridge|newton|somerville|quincy|lynn|brockton|framingham|haverhill|malden|medford|taunton|chicopee|weymouth|revere|peabody|methuen|barnstable|pittsfield|attleboro|salem|westfield|holyoke|leominster|fitchburg|beverley|lawrence|marlborough|woburn|amherst|watertown|shrewsbury|agawam|franklin|braintree|randolph|everett|waltham|gloucester|danvers|chelmsford|andover|natick|norwood|needham|westwood|milford|stoughton|reading|winchester|lexington|billerica|burlington|wilmington|tewksbury|dracut|acton|concord|sudbury|wayland|weston|wellesley|brookline|newton|watertown|belmont|arlington|medford|somerville|cambridge|charlestown|southboston|eastboston|backbay|beacon|north|south|west|east|central|downtown|uptown|midtown|lower|upper|inner|outer|old|new|greater|metro|suburban|urban|rural|county|parish|borough|township|village|town|city|state|province|region|district|area|zone|sector|quarter|neighborhood|ward|precinct|division|department|bureau|agency|office|ministry|commission|council|board|committee|panel|group|team|unit|squad|force|corps|regiment|battalion|company|platoon|squad|crew|staff|personnel|workforce|employees|workers|members|participants|attendees|guests|visitors|customers|clients|users|subscribers|followers|fans|supporters|advocates|volunteers|donors|sponsors|partners|allies|associates|colleagues|friends|family|relatives|neighbors|community|society|organization|association|institution|foundation|trust|charity|nonprofit|ngo|government|federal|national|international|global|worldwide|universal|public|private|corporate|commercial|business|enterprise|company|corporation|llc|inc|ltd|plc|gmbh|sarl|sas|spa|bv|ab|oy|as|sa|ag|kg|ohg|kgaa|se|scrl|cvba|sprl|bvba|nv|sl|srl|scp|scpa|snc|scs|sas|sasu|sarl|eurl|eirl|auto|micro|entreprise|individual|sole|proprietorship|partnership|joint|venture|consortium|alliance|coalition|federation|union|league|guild|club|society|association|organization|institution|foundation|trust|charity|nonprofit|ngo|government|federal|national|international|global|worldwide|universal|public|private|corporate|commercial|business|enterprise)$/ }
    
    # Combine both sources
    potential_parties = (proper_nouns + brand_names).uniq
    
    entities[:party1] = potential_parties[0] if potential_parties[0]
    entities[:party2] = potential_parties[1] if potential_parties[1]
    
    # Extract dollar amounts
    if description =~ /\$?(\d+(?:,\d{3})*(?:\.\d{2})?)\s*dollars?/i
      entities[:amount] = "$#{$1}"
    elsif description =~ /(\d+)\s*dollars?/i
      entities[:amount] = "$#{$1}"
    end
    
    # Extract time periods
    if description =~ /(\d+)\s*weeks?/i
      entities[:duration] = "#{$1} week(s)"
    elsif description =~ /(\d+)\s*months?/i
      entities[:duration] = "#{$1} month(s)"
    elsif description =~ /(\d+)\s*days?/i
      entities[:duration] = "#{$1} day(s)"
    end
    
    # Extract deliverables count
    if description =~ /(\d+)\s*videos?/i
      entities[:video_count] = $1
      entities[:content_type] = "video"
    elsif description =~ /(\d+)\s*posts?/i
      entities[:post_count] = $1
      entities[:content_type] = "post"
    end
    
    entities
  end

  def generate_scope_section(entities)
    if entities[:content_type] && entities[:video_count]
      "The Brand engages the Influencer to create and publish **#{entities[:video_count]} #{entities[:content_type]} content posts** on the Influencer's social media platforms#{entities[:duration] ? " over a period of **#{entities[:duration]}**" : ""}."
    else
      "The parties agree to collaborate as described in the original request: #{@description}"
    end
  end

  def generate_deliverables_section(entities)
    if entities[:video_count] && entities[:content_type]
      <<~DELIVERABLES
        * Influencer shall create **#{entities[:video_count]} original #{entities[:content_type]} posts** as specified.
        * Content shall be posted on platforms agreed by both parties (e.g., Instagram, YouTube, TikTok, etc.).
        * Content shall remain live for a minimum of **30 days** post-publication.
      DELIVERABLES
    else
      "* Deliverables shall be as specified in the original description: #{@description}"
    end
  end

  def generate_compensation_section(entities)
    if entities[:amount]
      <<~COMPENSATION
        * The Brand agrees to pay the Influencer a total of **#{entities[:amount]}** for the services described above.
        * Payment will be made **within 5 business days** after completion of the campaign and submission of all deliverables.
      COMPENSATION
    else
      "* Compensation shall be as specified in the original description: #{@description}"
    end
  end

  def generate_timeline_section(entities)
    if entities[:duration]
      <<~TIMELINE
        * Campaign duration: **#{entities[:duration]}** starting from **[Start Date]** to **[End Date]**.
        * Posting schedule to be mutually agreed upon before the start of the campaign.
      TIMELINE
    else
      "* Timeline shall be as specified in the original description: #{@description}"
    end
  end

  # Additional contract type generators (simplified versions)
  def generate_partnership_contract
    generate_basic_contract.gsub("CONTRACT AGREEMENT", "PARTNERSHIP AGREEMENT")
  end

  def generate_service_contract
    generate_basic_contract.gsub("CONTRACT AGREEMENT", "SERVICE AGREEMENT")
  end

  def generate_employment_contract
    generate_basic_contract.gsub("CONTRACT AGREEMENT", "EMPLOYMENT AGREEMENT")
  end

  def generate_nda_contract
    generate_basic_contract.gsub("CONTRACT AGREEMENT", "NON-DISCLOSURE AGREEMENT")
  end
end