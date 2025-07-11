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
    @timeout = 60
    @max_retries = 2
    @openai_client = setup_openai_client if OPENAI_API_KEY.present?
  end

  def generate
    retries = 0

    begin
      Rails.logger.info "Direct AI generation started for: #{@description}"
      
      # Try OpenAI first
      if @openai_client
        Rails.logger.info "Attempting OpenAI generation"
        ai_response = generate_with_openai
        
        if ai_response.present?
          Rails.logger.info "OpenAI generation successful: #{ai_response.length} chars"
          return ai_response
        else
          Rails.logger.warn "OpenAI generation failed or empty response"
        end
      else
        Rails.logger.warn "OpenAI client not available, API key: #{OPENAI_API_KEY.present? ? 'present' : 'missing'}"
      end

      # Try Hugging Face as fallback
      Rails.logger.info "Attempting Hugging Face generation"
      ai_response = generate_with_huggingface
      
      if ai_response.present?
        Rails.logger.info "Hugging Face generation successful: #{ai_response.length} chars"
        return ai_response
      else
        Rails.logger.warn "Hugging Face generation failed or empty response"
      end

      # Final fallback
      Rails.logger.warn "All AI services failed, returning fallback message"
      return "I'm unable to generate a response at the moment. Please try again later or contact support."
      
    rescue => e
      retries += 1
      if retries <= @max_retries
        Rails.logger.warn "AI generation attempt #{retries} failed: #{e.message}. Retrying..."
        sleep(1)
        retry
      else
        Rails.logger.error "AI generation failed after #{@max_retries} attempts: #{e.message}"
        return "I'm experiencing technical difficulties. Please try again later."
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
    
    response = @openai_client.chat(
      parameters: {
        model: 'gpt-3.5-turbo',
        messages: [
          {
            role: "user", 
            content: @description
          }
        ],
        max_tokens: 1500,
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

  def generate_with_huggingface
    HUGGINGFACE_MODELS.each do |model_url|
      begin
        Rails.logger.info "Trying Hugging Face model: #{model_url}"
        response = call_huggingface_api(model_url)
        if response.present?
          Rails.logger.info "Hugging Face response received: #{response.length} characters"
          return response
        end
      rescue => e
        Rails.logger.warn "Hugging Face model #{model_url} failed: #{e.message}"
        next
      end
    end
    
    return nil
  end

  def call_huggingface_api(model_url)
    uri = URI(model_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = @timeout
    
    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{HUGGINGFACE_API_KEY}"
    request['Content-Type'] = 'application/json'
    
    request.body = {
      inputs: @description,
      parameters: {
        max_length: 500,
        temperature: 0.7,
        return_full_text: false
      }
    }.to_json
    
    response = http.request(request)
    
    if response.code == '200'
      result = JSON.parse(response.body)
      if result.is_a?(Array) && result.first.is_a?(Hash)
        generated_text = result.first['generated_text']
        return generated_text.strip if generated_text.present?
      end
    else
      Rails.logger.error "Hugging Face API error: #{response.code} - #{response.body}"
    end
    
    return nil
  rescue => e
    Rails.logger.error "Hugging Face API call failed: #{e.message}"
    return nil
  end
end