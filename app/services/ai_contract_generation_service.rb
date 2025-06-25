class AiContractGenerationService
  # Updated to use models that are actually deployed on Hugging Face Inference API
  # Alternative models to try (uncomment one):
  # API_URL = 'https://api-inference.huggingface.co/models/microsoft/DialoGPT-large'
   API_URL = 'https://api-inference.huggingface.co/models/gpt2'
  # API_URL = 'https://api-inference.huggingface.co/models/EleutherAI/gpt-neo-1.3B'
  # API_URL = 'https://api-inference.huggingface.co/models/microsoft/DialoGPT-small'
  
  API_KEY = Rails.application.credentials.huggingface_api_key || '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'

  def initialize(description)
    @description = description
    @timeout = 60
    @max_retries = 3
  end

  def generate
    retries = 0

    begin
      # First, let's try to check if the model is available
      if !model_available?
        Rails.logger.warn "Model not available, falling back to template"
        return generate_contract_template
      end
      
      ai_generated_content = call_huggingface_api(@description)
      
      if ai_generated_content.present? && valid_contract_content?(ai_generated_content)
        Rails.logger.info("HuggingFace contract response: #{ai_generated_content.truncate(500)}")
        return format_ai_contract(ai_generated_content)
      else
        Rails.logger.warn "AI generation failed or invalid, falling back to template"
        return generate_contract_template
      end
    rescue => e
      retries += 1
      if retries <= @max_retries
        Rails.logger.warn "AI Contract Generation attempt #{retries} failed: #{e.message}. Retrying..."
        sleep(2 ** retries)
        retry
      else
        Rails.logger.error "AI Contract Generation failed after #{@max_retries} attempts: #{e.message}"
        generate_contract_template
      end
    end
  end

  private

  def model_available?
    begin
      uri = URI(API_URL)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 10
      http.open_timeout = 10

      request = Net::HTTP::Get.new(uri)
      request['Authorization'] = "Bearer #{API_KEY}"
      
      response = http.request(request)
      
      # If we get a 200 or 503 (model loading), the model exists
      return response.code == '200' || response.code == '503'
    rescue
      return false
    end
  end

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

    prompt = build_contract_prompt(description)

    # Request body compatible with most text generation models
    request.body = {
      inputs: prompt,
      parameters: {
        max_length: 1500,
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
    Rails.logger.info("HuggingFace raw response: #{response.code} | #{response.body.truncate(1000)}")

    case response.code
    when '200'
      result = JSON.parse(response.body)
      extract_generated_content(result, prompt)
    when '404'
      Rails.logger.error "Model not found (404). The model may be unavailable or the URL is incorrect."
      Rails.logger.error "Attempted URL: #{API_URL}"
      raise "Model not found - 404 error"
    when '503'
      Rails.logger.warn "Model is loading, retrying..."
      sleep(10)
      raise "Model is loading"
    when '429'
      Rails.logger.warn "Rate limit exceeded"
      raise "Rate limit exceeded"
    when '401', '403'
      Rails.logger.error "Authentication failed. Check your API key."
      raise "Authentication error: #{response.code}"
    else
      Rails.logger.error "Hugging Face API error: #{response.code} - #{response.body}"
      raise "API Error: #{response.code}"
    end
  rescue JSON::ParserError => e
    Rails.logger.error "Failed to parse JSON response: #{e.message}"
    raise "Invalid JSON response from API"
  rescue Net::TimeoutError => e
    Rails.logger.error "Request timeout: #{e.message}"
    raise "Request timeout"
  rescue StandardError => e
    Rails.logger.error "Unexpected error in API call: #{e.message}"
    raise e
  end

  def build_contract_prompt(description)
    contract_type = determine_contract_type(description)
    # Prompt optimized for conversational models like DialoGPT
    <<~PROMPT
      Human: I need help creating a professional legal contract. Here are the details:

      Description: #{description}
      Contract Type: #{contract_type}

      Please create a comprehensive contract that includes:
      - Title and party identification
      - Scope of work/services
      - Payment terms
      - Timeline and deliverables
      - Responsibilities
      - Termination clauses
      - Signature section

      Assistant: I'll create a professional contract for you.

      #{contract_type.upcase}

      This Agreement is entered into on [DATE] between [PARTY_A] and [PARTY_B].

      WHEREAS, the parties wish to establish the terms and conditions for #{description.downcase};

      NOW, THEREFORE, the parties agree as follows:

      1. SCOPE OF WORK
    PROMPT
  end

  def determine_contract_type(description)
    description_lower = description.to_s.downcase

    return "Non-Disclosure Agreement"    if description_lower.include?("confidential") || description_lower.include?("nda") || description_lower.include?("non-disclosure") || description_lower.include?("secret") || description_lower.include?("sensitive") || description_lower.include?("proprietary")
    return "Influencer Collaboration"    if description_lower.include?("influencer") || description_lower.include?("social media")
    return "Sponsorship Agreement"       if description_lower.include?("sponsor")   || description_lower.include?("event")
    return "Service Agreement"           if description_lower.include?("service")   || description_lower.include?("freelance")
    return "Employment Contract"         if description_lower.include?("employ")    || description_lower.include?("job")
    return "Gifting Agreement"           if description_lower.include?("gift")      || description_lower.include?("product")

    "General Service Agreement"
  end

  def extract_generated_content(result, prompt)
    generated_text = nil

    # Handle different response formats from Hugging Face
    if result.is_a?(Array) && !result.empty?
      if result.first.is_a?(Hash)
        generated_text = result.first['generated_text'] || result.first['text']
      elsif result.first.is_a?(String)
        generated_text = result.first
      end
    elsif result.is_a?(Hash)
      generated_text = result['generated_text'] || result['text'] || result.dig(0, 'generated_text')
    elsif result.is_a?(String)
      generated_text = result
    end

    return nil unless generated_text
    extract_contract_content(generated_text, prompt)
  end

  def extract_contract_content(generated_text, prompt)
    # Remove the original prompt from the response
    contract_content = generated_text.to_s.gsub(prompt, '').strip

    # Clean up the content
    contract_content = contract_content
      .gsub(/\n{3,}/, "\n\n")
      .gsub(/^\s+/, '')
      .gsub(/\t/, '    ')
      .gsub(/\r\n/, "\n")
      .strip

    return nil if contract_content.length < 200  # Reduced minimum length
    
    # More flexible validation
    return nil unless contract_content.match?(/agreement|contract|terms/i)

    # Add contract header if missing
    unless contract_content.match?(/^\s*\w+\s+(AGREEMENT|CONTRACT)/i)
      contract_content = "CONTRACT AGREEMENT\n\n" + contract_content
    end

    contract_content
  end

  def valid_contract_content?(content)
    return false if content.blank? || content.length < 200  # Reduced minimum length

    essential_elements = [
      /agreement|contract|terms/i,
      /part(y|ies)|client|service/i
    ]

    essential_elements.any? { |pattern| content.match?(pattern) }  # Changed from all to any
  end

  def format_ai_contract(ai_content)
    formatted_content = ai_content.strip

    unless formatted_content.include?('Signature')
      formatted_content += "\n\n" + signature_section
    end

    formatted_content += "\n\n" + generation_metadata
    formatted_content.strip
  end

  def signature_section
    <<~SIGNATURE
      IN WITNESS WHEREOF, the parties hereto have executed this Agreement as of the date first written above.

      PARTY A:                               PARTY B:

      _____________________                  _____________________
      Signature                             Signature

      _____________________                  _____________________
      Name: [PARTY_A_NAME]                  Name: [PARTY_B_NAME]

      _____________________                  _____________________
      Designation: [TITLE]                  Designation: [TITLE]

      _____________________                  _____________________
      Date: [DATE]                          Date: [DATE]

      WITNESSES:

      1. _____________________              2. _____________________
         Signature                             Signature
         Name: [WITNESS_1_NAME]                Name: [WITNESS_2_NAME]
         Address: [WITNESS_1_ADDRESS]          Address: [WITNESS_2_ADDRESS]
    SIGNATURE
  end

  def generation_metadata
    <<~METADATA
      ---
      Document Generation Details:
      - Generated on: #{Time.current.strftime('%d/%m/%Y at %H:%M:%S')}
      - Generation method: AI-assisted template
      - Based on description: #{@description.to_s.truncate(100)}
      - Jurisdiction: As per Indian law and practice
      - Legal Notice: This is a draft agreement and must be reviewed by qualified legal counsel before execution
      - Stamp Duty: Please ensure appropriate stamp duty is paid as per applicable state laws
    METADATA
  end

  def generate_contract_template
    contract_type = determine_contract_type(@description)

    template_content = case contract_type.downcase
    when /non-disclosure|nda|confidential/
      nda_template_indian
    when /influencer/
      influencer_template_indian
    when /sponsor/
      sponsorship_template_indian
    when /service/
      service_template_indian
    when /employment/
      employment_template_indian
    when /gift/
      gifting_template_indian
    else
      general_template_indian
    end

    template_content + "\n\n" + signature_section + "\n\n" + generation_metadata
  end

  def nda_template_indian
    <<~TEMPLATE
      NON-DISCLOSURE AGREEMENT

      THIS AGREEMENT is made on this #{Date.current.strftime('%d')} day of #{Date.current.strftime('%B')}, #{Date.current.year} between:

      [DISCLOSING_PARTY_NAME], a company incorporated under the Companies Act, 2013 having its registered office at [DISCLOSING_PARTY_ADDRESS] (hereinafter referred to as "Disclosing Party", which expression shall, unless repugnant to the context, include its successors and permitted assigns) of the FIRST PART;

      AND

      [RECEIVING_PARTY_NAME], a company incorporated under the Companies Act, 2013 having its registered office at [RECEIVING_PARTY_ADDRESS] (hereinafter referred to as "Receiving Party", which expression shall, unless repugnant to the context, include its successors and permitted assigns) of the SECOND PART.

      WHEREAS the Disclosing Party desires to disclose certain confidential information relating to #{@description} to the Receiving Party for the purpose of [PURPOSE_OF_DISCLOSURE];

      WHEREAS the Receiving Party is willing to receive such confidential information subject to the terms and conditions set forth herein;

      NOW THEREFORE, in consideration of the mutual covenants and agreements contained herein, the parties agree as follows:

      1. DEFINITION OF CONFIDENTIAL INFORMATION
         1.1 "Confidential Information" shall mean and include all information, data, materials, and know-how disclosed by the Disclosing Party to the Receiving Party, whether orally, in writing, or in any other form, including but not limited to:
             (a) Technical data, formulae, patterns, compilations, programs, devices, methods, techniques, drawings, processes, financial data, financial plans, product plans, or list of actual or potential customers or suppliers;
             (b) Business strategies, marketing plans, pricing information, and commercial information;
             (c) Any information marked as "Confidential" or "Proprietary" or which would reasonably be considered confidential under the circumstances.

      2. NON-DISCLOSURE OBLIGATIONS
         2.1 The Receiving Party undertakes and agrees:
             (a) To maintain the confidentiality of all Confidential Information received from the Disclosing Party;
             (b) Not to disclose, reveal, or make available the Confidential Information to any third party without the prior written consent of the Disclosing Party;
             (c) To use the Confidential Information solely for the purpose for which it was disclosed;
             (d) To take reasonable measures to protect the confidentiality of the Confidential Information, which shall be no less than the measures it takes to protect its own confidential information.

      3. EXCEPTIONS
         3.1 The obligations under this Agreement shall not apply to information that:
             (a) Is or becomes publicly available through no breach of this Agreement by the Receiving Party;
             (b) Was rightfully known to the Receiving Party prior to disclosure by the Disclosing Party;
             (c) Is rightfully received by the Receiving Party from a third party without breach of any confidentiality obligation;
             (d) Is required to be disclosed by law or court order, provided that the Receiving Party gives the Disclosing Party reasonable prior notice.

      4. RETURN OF CONFIDENTIAL INFORMATION
         4.1 Upon termination of this Agreement or upon written request by the Disclosing Party, the Receiving Party shall promptly return or destroy all documents, materials, and other tangible manifestations of Confidential Information.

      5. TERM AND TERMINATION
         5.1 This Agreement shall commence on the date first written above and shall continue for a period of [DURATION] years, unless terminated earlier in accordance with the provisions hereof.
         5.2 The obligations of confidentiality shall survive the termination of this Agreement and shall continue for a period of [SURVIVAL_PERIOD] years from the date of termination.

      6. REMEDIES
         6.1 The Receiving Party acknowledges that any breach of this Agreement may cause irreparable harm to the Disclosing Party for which monetary damages would be inadequate, and therefore the Disclosing Party shall be entitled to seek injunctive relief and specific performance.

      7. GOVERNING LAW AND JURISDICTION
         7.1 This Agreement shall be governed by and construed in accordance with the laws of India.
         7.2 Any disputes arising out of or in connection with this Agreement shall be subject to the exclusive jurisdiction of the courts in [JURISDICTION_CITY].

      8. ENTIRE AGREEMENT
         8.1 This Agreement constitutes the entire agreement between the parties and supersedes all prior negotiations, representations, or agreements relating to the subject matter hereof.

      9. AMENDMENT
         9.1 This Agreement may only be amended or modified by a written instrument signed by both parties.

      10. SEVERABILITY
          10.1 If any provision of this Agreement is held to be invalid or unenforceable, the remaining provisions shall continue in full force and effect.
    TEMPLATE
  end

  def influencer_template_indian
    <<~TEMPLATE
      INFLUENCER COLLABORATION AGREEMENT

      THIS AGREEMENT is made on this #{Date.current.strftime('%d')} day of #{Date.current.strftime('%B')}, #{Date.current.year} between:

      [BRAND_NAME], a company incorporated under the Companies Act, 2013 having its registered office at [BRAND_ADDRESS] (hereinafter referred to as "Brand", which expression shall, unless repugnant to the context, include its successors and permitted assigns) of the FIRST PART;

      AND

      [INFLUENCER_NAME], an individual residing at [INFLUENCER_ADDRESS] (hereinafter referred to as "Influencer") of the SECOND PART.

      WHEREAS the Brand desires to engage the Influencer for promoting its products/services through digital content creation;

      WHEREAS the Influencer agrees to create and publish content in accordance with the terms and conditions set forth herein;

      NOW THEREFORE, in consideration of the mutual covenants contained herein, the parties agree as follows:

      1. CAMPAIGN DETAILS
         1.1 Campaign Description: #{@description}
         1.2 Campaign Duration: From [START_DATE] to [END_DATE]
         1.3 Platform(s): [SOCIAL_MEDIA_PLATFORMS]

      2. SCOPE OF WORK
         2.1 The Influencer shall create and publish the following content:
             (a) [NUMBER] Instagram posts featuring Brand's products
             (b) [NUMBER] Instagram stories
             (c) [OTHER_DELIVERABLES]

      3. CONTENT GUIDELINES
         3.1 All content shall be original, authentic, and align with Brand's values
         3.2 Content must comply with platform guidelines and applicable laws
         3.3 Proper disclosure hashtags must be used (#ad, #sponsored, #partnership) as per ASCI guidelines
         3.4 Content must be approved by Brand before publication

      4. COMPENSATION
         4.1 Total Compensation: ₹[AMOUNT] (Rupees [AMOUNT_IN_WORDS])
         4.2 Payment Terms: [PAYMENT_SCHEDULE]
         4.3 TDS shall be deducted as per applicable tax laws
         4.4 Additional Benefits: [PRODUCTS/SERVICES_IF_ANY]

      5. INTELLECTUAL PROPERTY RIGHTS
         5.1 The Influencer retains copyright in the original content created
         5.2 The Brand is granted a non-exclusive, perpetual license to use the content for marketing purposes
         5.3 The Brand may cross-post content on its official channels with proper attribution

      6. COMPLIANCE WITH LAWS
         6.1 Both parties shall comply with all applicable laws including but not limited to:
             (a) Advertising Standards Council of India (ASCI) Guidelines
             (b) Information Technology Act, 2000
             (c) Consumer Protection Act, 2019
             (d) Goods and Services Tax Act, 2017

      7. TERMINATION
         7.1 Either party may terminate this Agreement with [NOTICE_PERIOD] days written notice
         7.2 Upon termination, the Influencer shall complete all committed deliverables

      8. GOVERNING LAW
         8.1 This Agreement shall be governed by Indian law
         8.2 Disputes shall be subject to the jurisdiction of courts in [CITY]

      9. FORCE MAJEURE
         9.1 Neither party shall be liable for delays due to circumstances beyond reasonable control
    TEMPLATE
  end

  def service_template_indian
    <<~TEMPLATE
      SERVICE AGREEMENT

      THIS AGREEMENT is made on this #{Date.current.strftime('%d')} day of #{Date.current.strftime('%B')}, #{Date.current.year} between:

      [CLIENT_NAME], a company incorporated under the Companies Act, 2013 having its registered office at [CLIENT_ADDRESS] (hereinafter referred to as "Client", which expression shall, unless repugnant to the context, include its successors and permitted assigns) of the FIRST PART;

      AND

      [SERVICE_PROVIDER_NAME], a company incorporated under the Companies Act, 2013 having its registered office at [SERVICE_PROVIDER_ADDRESS] (hereinafter referred to as "Service Provider", which expression shall, unless repugnant to the context, include its successors and permitted assigns) of the SECOND PART.

      WHEREAS the Client desires to engage the Service Provider for #{@description};

      WHEREAS the Service Provider agrees to provide such services subject to the terms and conditions herein;

      NOW THEREFORE, in consideration of the mutual covenants contained herein, the parties agree as follows:

      1. SCOPE OF SERVICES
         1.1 The Service Provider shall provide the following services:
             (a) [DETAILED_SERVICE_DESCRIPTION]
             (b) [SPECIFIC_DELIVERABLES]
             (c) [PERFORMANCE_STANDARDS]

      2. TERM AND TIMELINE
         2.1 Commencement Date: [START_DATE]
         2.2 Completion Date: [END_DATE]
         2.3 Key Milestones: [MILESTONE_DETAILS]

      3. CONSIDERATION AND PAYMENT
         3.1 Total Service Fee: ₹[AMOUNT] (Rupees [AMOUNT_IN_WORDS]) plus applicable taxes
         3.2 Payment Schedule: [PAYMENT_TERMS]
         3.3 GST shall be charged as per applicable rates
         3.4 TDS shall be deducted as per Income Tax Act, 1961

      4. OBLIGATIONS OF THE CLIENT
         4.1 Provide necessary information, materials, and access
         4.2 Timely approval and feedback
         4.3 Payment as per agreed terms
         4.4 Cooperation for smooth execution of services

      5. OBLIGATIONS OF THE SERVICE PROVIDER
         5.1 Perform services with due care and diligence
         5.2 Maintain confidentiality of Client's information
         5.3 Comply with all applicable laws and regulations
         5.4 Deliver services as per agreed specifications and timeline

      6. INTELLECTUAL PROPERTY
         6.1 All work product developed specifically for the Client shall belong to the Client
         6.2 Service Provider's pre-existing intellectual property shall remain with the Service Provider
         6.3 Client grants necessary licenses for Service Provider to perform the services

      7. CONFIDENTIALITY
         7.1 Both parties shall maintain confidentiality of each other's proprietary information
         7.2 Confidentiality obligations shall survive termination of this Agreement

      8. LIMITATION OF LIABILITY
         8.1 Service Provider's total liability shall not exceed the total fees paid under this Agreement
         8.2 Neither party shall be liable for indirect, consequential, or special damages

      9. TERMINATION
         9.1 Either party may terminate with [NOTICE_PERIOD] days written notice
         9.2 Immediate termination allowed for material breach not cured within [CURE_PERIOD] days
         9.3 Upon termination, Service Provider shall deliver all work completed

      10. DISPUTE RESOLUTION
          10.1 Disputes shall first be resolved through mutual consultation
          10.2 Unresolved disputes shall be referred to arbitration under Arbitration and Conciliation Act, 2015
          10.3 Seat of arbitration shall be [ARBITRATION_SEAT]

      11. GOVERNING LAW
          11.1 This Agreement shall be governed by Indian law
          11.2 Courts in [JURISDICTION] shall have exclusive jurisdiction
    TEMPLATE
  end

  def employment_template_indian
    <<~TEMPLATE
      EMPLOYMENT AGREEMENT

      THIS AGREEMENT is made on this #{Date.current.strftime('%d')} day of #{Date.current.strftime('%B')}, #{Date.current.year} between:

      [COMPANY_NAME], a company incorporated under the Companies Act, 2013 having its registered office at [COMPANY_ADDRESS] (hereinafter referred to as "Company", which expression shall, unless repugnant to the context, include its successors and permitted assigns) of the FIRST PART;

      AND

      [EMPLOYEE_NAME], an individual residing at [EMPLOYEE_ADDRESS] (hereinafter referred to as "Employee") of the SECOND PART.

      WHEREAS the Company desires to employ the Employee in the capacity of #{@description};

      WHEREAS the Employee agrees to serve the Company subject to the terms and conditions herein;

      NOW THEREFORE, the parties agree as follows:

      1. EMPLOYMENT TERMS
         1.1 Position: [JOB_TITLE]
         1.2 Department: [DEPARTMENT]
         1.3 Reporting Manager: [MANAGER_NAME]
         1.4 Date of Joining: [START_DATE]
         1.5 Place of Work: [WORK_LOCATION]

      2. COMPENSATION AND BENEFITS
         2.1 Monthly Salary: ₹[MONTHLY_SALARY] (Rupees [AMOUNT_IN_WORDS])
         2.2 Annual CTC: ₹[ANNUAL_CTC] (Rupees [AMOUNT_IN_WORDS])
         2.3 Salary Components: [BREAK_UP_DETAILS]
         2.4 Benefits: [BENEFITS_DETAILS]
         2.5 Performance Bonus: [BONUS_STRUCTURE]

      3. DUTIES AND RESPONSIBILITIES
         3.1 The Employee shall perform duties as assigned by the Company
         3.2 Employee shall devote full time and attention to Company's business
         3.3 Employee shall maintain highest standards of conduct and professionalism
         3.4 Employee shall comply with all Company policies and procedures

      4. WORKING HOURS AND LEAVE
         4.1 Working Hours: [HOURS_PER_WEEK] hours per week
         4.2 Working Days: [WORKING_DAYS]
         4.3 Leave Entitlement as per Company policy and applicable laws
         4.4 Overtime compensation as per applicable laws

      5. CONFIDENTIALITY AND NON-DISCLOSURE
         5.1 Employee shall maintain strict confidentiality of Company's proprietary information
         5.2 Employee shall not disclose confidential information to third parties
         5.3 These obligations shall survive termination of employment

      6. NON-COMPETE AND NON-SOLICITATION
         6.1 During employment and for [RESTRICTION_PERIOD] after termination, Employee shall not:
             (a) Engage in competing business within [GEOGRAPHICAL_AREA]
             (b) Solicit Company's clients or employees
             (c) Use Company's confidential information for personal benefit

      7. INTELLECTUAL PROPERTY
         7.1 All intellectual property created during employment shall belong to the Company
         7.2 Employee shall execute necessary documents to assign such rights to the Company

      8. TERMINATION
         8.1 Company may terminate employment with [NOTICE_PERIOD] months notice or payment in lieu
         8.2 Employee may resign with [EMPLOYEE_NOTICE_PERIOD] months notice
         8.3 Company may terminate immediately for cause without notice or payment
         8.4 Upon termination, Employee shall return all Company property

      9. STATUTORY COMPLIANCE
         9.1 This Agreement is subject to applicable labor laws including:
             (a) Industrial Employment (Standing Orders) Act, 1946
             (b) Employees' Provident Fund and Miscellaneous Provisions Act, 1952
             (c) Employees' State Insurance Act, 1948
             (d) Payment of Wages Act, 1936
             (e) Payment of Gratuity Act, 1972

      10. GOVERNING LAW
          10.1 This Agreement shall be governed by Indian law
          10.2 Disputes shall be subject to jurisdiction of courts in [CITY]
    TEMPLATE
  end

  def sponsorship_template_indian
    <<~TEMPLATE
      SPONSORSHIP AGREEMENT

      THIS AGREEMENT is made on this #{Date.current.strftime('%d')} day of #{Date.current.strftime('%B')}, #{Date.current.year} between:

      [SPONSOR_NAME], a company incorporated under the Companies Act, 2013 having its registered office at [SPONSOR_ADDRESS] (hereinafter referred to as "Sponsor", which expression shall, unless repugnant to the context, include its successors and permitted assigns) of the FIRST PART;

      AND

      [ORGANIZER_NAME], a company incorporated under the Companies Act, 2013 having its registered office at [ORGANIZER_ADDRESS] (hereinafter referred to as "Organizer", which expression shall, unless repugnant to the context, include its successors and permitted assigns) of the SECOND PART.

      WHEREAS the Organizer is organizing #{@description};

      WHEREAS the Sponsor desires to sponsor the said event subject to the terms herein;

      NOW THEREFORE, the parties agree as follows:

      1. EVENT DETAILS
         1.1 Event Name: [EVENT_NAME]
         1.2 Event Date(s): [EVENT_DATES]
         1.3 Event Venue: [VENUE_DETAILS]
         1.4 Expected Attendance: [ATTENDEE_COUNT]

      2. SPONSORSHIP AMOUNT
         2.1 Sponsorship Fee: ₹[AMOUNT] (Rupees [AMOUNT_IN_WORDS])
         2.2 Payment Schedule: [PAYMENT_TERMS]
         2.3 GST shall be charged as applicable
         2.4 TDS shall be deducted as per Income Tax Act, 1961

      3. SPONSOR BENEFITS
         3.1 Logo placement on event materials and promotional content
         3.2 [NUMBER] complimentary passes/tickets
         3.3 Booth space of [DIMENSIONS] at the venue
         3.4 Speaking opportunity for [DURATION] minutes
         3.5 Digital marketing promotion on official channels
         3.6 [OTHER_SPECIFIC_BENEFITS]

      4. ORGANIZER OBLIGATIONS
         4.1 Provide promised benefits as per agreed specifications
         4.2 Ensure professional conduct of the event
         4.3 Provide post-event report with attendance and engagement metrics
         4.4 Maintain quality standards for the event

      5. SPONSOR OBLIGATIONS
         5.1 Provide logo and marketing materials as per specifications
         5.2 Ensure content is appropriate and complies with applicable laws
         5.3 Make payments as per agreed schedule
         5.4 Coordinate with Organizer for smooth execution

      6. INTELLECTUAL PROPERTY
         6.1 Each party retains ownership of their respective intellectual property
         6.2 Limited license granted for use during the event period
         6.3 Prior approval required for any additional usage

      7. CANCELLATION AND FORCE MAJEURE
         7.1 Event cancellation by Organizer: [REFUND_TERMS]
         7.2 Sponsor withdrawal: [PENALTY_TERMS]
         7.3 Force Majeure events: [FORCE_MAJEURE_CLAUSE]

      8. LIABILITY AND INDEMNIFICATION
         8.1 Each party shall indemnify the other against third-party claims
         8.2 Organizer shall maintain adequate insurance coverage
         8.3 Limitation of liability as per applicable laws

      9. GOVERNING LAW
         9.1 This Agreement shall be governed by Indian law
         9.2 Disputes shall be subject to jurisdiction of courts in [CITY]
    TEMPLATE
  end

  def gifting_template_indian
    <<~TEMPLATE
      PRODUCT GIFTING AGREEMENT

      THIS AGREEMENT is made on this #{Date.current.strftime('%d')} day of #{Date.current.strftime('%B')}, #{Date.current.year} between:

      [BRAND_NAME], a company incorporated under the Companies Act, 2013 having its registered office at [BRAND_ADDRESS] (hereinafter referred to as "Brand", which expression shall, unless repugnant to the context, include its successors and permitted assigns) of the FIRST PART;

      AND

      [RECIPIENT_NAME], an individual residing at [RECIPIENT_ADDRESS] (hereinafter referred to as "Recipient") of the SECOND PART.

      WHEREAS the Brand desires to provide certain products to the Recipient for #{@description};

      WHEREAS the Recipient agrees to receive such products subject to the terms herein;

      NOW THEREFORE, the parties agree as follows:

      1. GIFTED PRODUCTS
         1.1 Products: [PRODUCT_DETAILS]
         1.2 Estimated Value: ₹[VALUE] (Rupees [VALUE_IN_WORDS])
         1.3 Delivery Method: [DELIVERY_DETAILS]
         1.4 Delivery Timeline: [DELIVERY_DATE]

      2. RECIPIENT OBLIGATIONS
         2.1 Create authentic content featuring the products
         2.2 Minimum [NUMBER] social media posts within [TIMEFRAME]
         2.3 Include proper disclosure as per ASCI guidelines (#gifted, #pr, #collaboration)
         2.4 Tag Brand's official social media handles

      3. CONTENT GUIDELINES
         3.1 Content must be original and authentic
         3.2 Comply with platform terms and applicable laws
         3.3 Maintain professional standards
         3.4 No guarantee of positive reviews required

      4. INTELLECTUAL PROPERTY
         4.1 Recipient retains ownership of created content
         4.2 Brand may repost with proper attribution
         4.3 No exclusive rights granted to Brand

      5. TAX IMPLICATIONS
         5.1 Recipient acknowledges tax liability on gifted products as per Income Tax Act, 1961
         5.2 Brand may issue necessary certificates for tax compliance

      6. COMPLIANCE
         6.1 Both parties shall comply with:
             (a) ASCI Guidelines for Influencer Advertising
             (b) Information Technology Act, 2000
             (c) Consumer Protection Act, 2019

      7. TERMINATION
         7.1 Either party may terminate with written notice
         7.2 Completed obligations shall remain valid

      8. GOVERNING LAW
         8.1 This Agreement shall be governed by Indian law
         8.2 Disputes subject to jurisdiction of courts in [CITY]
    TEMPLATE
  end

  def general_template_indian
    <<~TEMPLATE
      GENERAL AGREEMENT

      THIS AGREEMENT is made on this #{Date.current.strftime('%d')} day of #{Date.current.strftime('%B')}, #{Date.current.year} between:

      [PARTY_A_NAME], a company incorporated under the Companies Act, 2013 having its registered office at [PARTY_A_ADDRESS] (hereinafter referred to as "Party A", which expression shall, unless repugnant to the context, include its successors and permitted assigns) of the FIRST PART;

      AND

      [PARTY_B_NAME], a company incorporated under the Companies Act, 2013 having its registered office at [PARTY_B_ADDRESS] (hereinafter referred to as "Party B", which expression shall, unless repugnant to the context, include its successors and permitted assigns) of the SECOND PART.

      WHEREAS the parties desire to enter into an agreement for #{@description};

      WHEREAS both parties have agreed to the terms and conditions set forth herein;

      NOW THEREFORE, in consideration of the mutual covenants and agreements contained herein, the parties agree as follows:

      1. SCOPE OF AGREEMENT
         1.1 Purpose: [DETAILED_PURPOSE]
         1.2 Objectives: [SPECIFIC_OBJECTIVES]
         1.3 Duration: [AGREEMENT_TERM]

      2. OBLIGATIONS OF PARTY A
         2.1 [PARTY_A_OBLIGATION_1]
         2.2 [PARTY_A_OBLIGATION_2]
         2.3 [PARTY_A_OBLIGATION_3]

      3. OBLIGATIONS OF PARTY B
         3.1 [PARTY_B_OBLIGATION_1]
         3.2 [PARTY_B_OBLIGATION_2]
         3.3 [PARTY_B_OBLIGATION_3]

      4. FINANCIAL TERMS
         4.1 Total Value: ₹[AMOUNT] (Rupees [AMOUNT_IN_WORDS])
         4.2 Payment Schedule: [PAYMENT_TERMS]
         4.3 GST shall be charged as applicable
         4.4 TDS deduction as per Income Tax Act, 1961

      5. PERFORMANCE STANDARDS
         5.1 Quality benchmarks and delivery standards
         5.2 Timeline for completion of obligations
         5.3 Monitoring and evaluation mechanisms

      6. INTELLECTUAL PROPERTY
         6.1 Ownership of existing intellectual property
         6.2 Rights in jointly developed intellectual property
         6.3 License grants and restrictions

      7. CONFIDENTIALITY
         7.1 Protection of proprietary information
         7.2 Non-disclosure of confidential matters
         7.3 Return of confidential materials upon termination

      8. TERMINATION
         8.1 Termination for convenience with [NOTICE_PERIOD] days notice
         8.2 Termination for cause with immediate effect
         8.3 Consequences of termination

      9. DISPUTE RESOLUTION
         9.1 Amicable resolution through mutual consultation
         9.2 Mediation by mutually agreed mediator
         9.3 Arbitration under Arbitration and Conciliation Act, 2015
         9.4 Seat of arbitration: [ARBITRATION_CITY]

      10. FORCE MAJEURE
          10.1 Neither party liable for delays due to circumstances beyond control
          10.2 Notification obligations during force majeure events
          10.3 Mitigation efforts and alternative arrangements

      11. GENERAL PROVISIONS
          11.1 Entire Agreement: This constitutes the complete agreement
          11.2 Amendment: Changes only through written agreement
          11.3 Severability: Invalid provisions don't affect remainder
          11.4 Waiver: No waiver except in writing
          11.5 Assignment: Rights not assignable without consent

      12. GOVERNING LAW AND JURISDICTION
          12.1 This Agreement shall be governed by the laws of India
          12.2 Subject to the exclusive jurisdiction of courts in [JURISDICTION_CITY]
          12.3 Compliance with all applicable Indian laws and regulations
    TEMPLATE
  end
end