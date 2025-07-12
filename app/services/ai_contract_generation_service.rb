class AiContractGenerationService
  require 'net/http'
  require 'json'
  require 'uri'
  
  # Configuration for different AI services
  OPENAI_API_KEY = Rails.application.credentials.openai_api_key || ENV['OPENAI_API_KEY']
  HUGGINGFACE_API_KEY = Rails.application.credentials.huggingface_api_key || ENV['HUGGINGFACE_API_KEY']
  GROQ_API_KEY = Rails.application.credentials.groq_api_key || ENV['GROQ_API_KEY']
  
  # Free AI API endpoints
  FREE_AI_SERVICES = [
    {
      name: 'Hugging Face Router',
      url: 'https://router.huggingface.co/v1/chat/completions',
      model: 'meta-llama/Llama-3.2-3B-Instruct',
      api_key: HUGGINGFACE_API_KEY,
      type: 'openai_compatible'
    },
    {
      name: 'Groq',
      url: 'https://api.groq.com/openai/v1/chat/completions',
      model: 'llama-3.2-3b-preview',
      api_key: GROQ_API_KEY,
      type: 'openai_compatible'
    },
    {
      name: 'Together AI',
      url: 'https://api.together.xyz/v1/chat/completions',
      model: 'meta-llama/Llama-3.2-3B-Instruct-Turbo',
      api_key: ENV['TOGETHER_API_KEY'],
      type: 'openai_compatible'
    }
  ].freeze

  def initialize(description)
    @description = description
    @timeout = 30
    @max_retries = 2
    @openai_client = setup_openai_client if OPENAI_API_KEY.present?
  end

  def generate
    retries = 0

    begin
      Rails.logger.info "AI contract generation started for: #{@description.truncate(100)}"
      
      # Try OpenAI first if available
      if @openai_client
        Rails.logger.info "Attempting OpenAI generation"
        ai_response = generate_with_openai
        
        if ai_response.present?
          Rails.logger.info "OpenAI generation successful: #{ai_response.length} chars"
          return ai_response
        else
          Rails.logger.warn "OpenAI generation failed or empty response"
        end
      end

      # Try free AI services
      ai_response = generate_with_free_services
      
      if ai_response.present?
        Rails.logger.info "Free AI service generation successful: #{ai_response.length} chars"
        return ai_response
      else
        Rails.logger.warn "All free AI services failed"
      end

      # Final fallback - generate a basic contract template
      Rails.logger.warn "All AI services failed, generating basic template"
      return generate_basic_contract_template
      
    rescue => e
      retries += 1
      if retries <= @max_retries
        Rails.logger.warn "AI generation attempt #{retries} failed: #{e.message}. Retrying..."
        sleep(2)
        retry
      else
        Rails.logger.error "AI generation failed after #{@max_retries} attempts: #{e.message}"
        return generate_basic_contract_template
      end
    end
  end

  private

  def setup_openai_client
    return nil unless OPENAI_API_KEY.present?
    
    begin
      require 'openai'
      OpenAI::Client.new(
        access_token: OPENAI_API_KEY,
        request_timeout: @timeout
      )
    rescue LoadError
      Rails.logger.warn "OpenAI gem not available"
      nil
    rescue => e
      Rails.logger.error "Failed to setup OpenAI client: #{e.message}"
      nil
    end
  end

  def generate_with_openai
    return nil unless @openai_client

    Rails.logger.info "Making OpenAI API call..."
    
    response = @openai_client.chat(
      parameters: {
        model: 'gpt-3.5-turbo',
        messages: [
          {
            role: "system",
            content: "You are a legal contract assistant. Generate a professional contract based on the user's description. Include all necessary legal clauses, terms, and conditions."
          },
          {
            role: "user", 
            content: @description
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
    
  rescue => e
    Rails.logger.error "OpenAI API error: #{e.message}"
    return nil
  end

  def generate_with_free_services
    FREE_AI_SERVICES.each do |service|
      next unless service[:api_key].present?
      
      begin
        Rails.logger.info "Trying #{service[:name]} with model #{service[:model]}"
        response = call_openai_compatible_api(service)
        
        if response.present?
          Rails.logger.info "#{service[:name]} response received: #{response.length} characters"
          return response
        end
      rescue => e
        Rails.logger.warn "#{service[:name]} failed: #{e.message}"
        next
      end
    end
    
    return nil
  end

  def call_openai_compatible_api(service)
    uri = URI(service[:url])
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = @timeout
    http.open_timeout = 10
    
    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{service[:api_key]}"
    request['Content-Type'] = 'application/json'
    
    # Enhanced prompt for better contract generation
    system_prompt = "You are a professional legal contract assistant. Generate a comprehensive, legally sound contract based on the user's description. Include:\n\n1. Clear parties identification\n2. Detailed terms and conditions\n3. Payment terms (if applicable)\n4. Deliverables and timeline\n5. Termination clauses\n6. Legal compliance statements\n\nFormat the contract professionally with proper sections and headings."
    
    request.body = {
      model: service[:model],
      messages: [
        {
          role: "system",
          content: system_prompt
        },
        {
          role: "user",
          content: @description
        }
      ],
      max_tokens: 2000,
      temperature: 0.7,
      stream: false
    }.to_json
    
    response = http.request(request)
    
    if response.code == '200'
      result = JSON.parse(response.body)
      
      if result.dig("choices", 0, "message", "content")
        generated_text = result["choices"][0]["message"]["content"]
        return generated_text.strip if generated_text.present?
      else
        Rails.logger.error "#{service[:name]} API response format unexpected: #{result.inspect}"
      end
    else
      Rails.logger.error "#{service[:name]} API error: #{response.code} - #{response.body}"
    end
    
    return nil
  rescue => e
    Rails.logger.error "#{service[:name]} API call failed: #{e.message}"
    return nil
  end

  def generate_basic_contract_template
    Rails.logger.info "Generating basic contract template as fallback"
    
    # Analyze description to determine contract type
    description_lower = @description.downcase
    
    contract_type = case description_lower
    when /service|freelance|work|project/
      'Service Agreement'
    when /nda|non-disclosure|confidential/
      'Non-Disclosure Agreement'
    when /employment|job|hire/
      'Employment Contract'
    when /influencer|social media|brand|collaboration/
      'Influencer Collaboration Agreement'
    when /sponsorship|sponsor/
      'Sponsorship Agreement'
    when /gift|product/
      'Product Gifting Agreement'
    else
      'General Agreement'
    end

    template = <<~CONTRACT
      # #{contract_type}

      **Date:** #{Date.current.strftime('%B %d, %Y')}

      ## Parties
      This agreement is entered into between:
      - **Party A:** [To be specified]
      - **Party B:** [To be specified]

      ## Description
      #{@description}

      ## Terms and Conditions

      ### 1. Scope of Work
      [To be defined based on the specific requirements outlined in the description above]

      ### 2. Duration
      This agreement shall commence on [Start Date] and continue until [End Date] or until terminated in accordance with the terms herein.

      ### 3. Compensation
      [Payment terms to be specified based on the nature of the agreement]

      ### 4. Responsibilities
      **Party A shall:**
      - [Specify responsibilities]

      **Party B shall:**
      - [Specify responsibilities]

      ### 5. Confidentiality
      Both parties agree to maintain the confidentiality of any proprietary information shared during the course of this agreement.

      ### 6. Termination
      Either party may terminate this agreement with [Notice Period] written notice to the other party.

      ### 7. Governing Law
      This agreement shall be governed by the laws of [Jurisdiction].

      ### 8. Entire Agreement
      This document constitutes the entire agreement between the parties and supersedes all prior negotiations, representations, or agreements.

      ## Signatures

      **Party A:**
      Signature: _________________________
      Name: [Print Name]
      Date: _____________

      **Party B:**
      Signature: _________________________
      Name: [Print Name]
      Date: _____________

      ---
      *This contract template was generated based on your description. Please review and customize all sections marked with brackets [...] to match your specific requirements. It's recommended to have this reviewed by a legal professional before execution.*
    CONTRACT

    template
  end
end