class AiContractGenerationService
  def initialize(description)
    @description = description
  end
  
  def generate
    begin
      # #Try to generate with Hugging Face API first
      ai_generated_content = call_huggingface_api(@description)
      
      if ai_generated_content && !ai_generated_content.empty?
        return format_ai_contract(ai_generated_content)
      else
        # Fallback to template if API fails
        return generate_contract_template
      end
    rescue => e
      Rails.logger.error "AI Contract Generation failed: #{e.message}"
      # Fallback to template on error
      generate_contract_template
    end
  end
  
  private
  
  def call_huggingface_api(description)
    require 'net/http'
    require 'json'
    
    uri = URI(API_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 30
    
    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{API_KEY}"
    request['Content-Type'] = 'application/json'
    
    # Craft a detailed prompt for contract generation
    prompt = build_contract_prompt(description)
    
    request.body = {
      inputs: prompt,
      parameters: {
        max_length: 1500,
        temperature: 0.7,
        do_sample: true,
        top_p: 0.9,
        repetition_penalty: 1.1
      },
      options: {
        wait_for_model: true
      }
    }.to_json
    
    response = http.request(request)
    
    if response.code == '200'
      result = JSON.parse(response.body)
      
      # Handle different response formats from Hugging Face
      if result.is_a?(Array) && result.first.is_a?(Hash)
        generated_text = result.first['generated_text'] || result.first['text']
      elsif result.is_a?(Hash)
        generated_text = result['generated_text'] || result['text']
      else
        generated_text = result.to_s
      end
      
      # Clean and extract the contract content
      extract_contract_content(generated_text, prompt)
    else
      Rails.logger.error "Hugging Face API error: #{response.code} - #{response.body}"
      nil
    end
  end
  
  def build_contract_prompt(description)
    <<~PROMPT
      Generate a professional legal contract based on the following description:
      
      Description: #{description}
      
      Create a comprehensive contract that includes:
      - Contract title and parties
      - Scope of work
      - Payment terms
      - Timeline and deliverables
      - Responsibilities of each party
      - Termination clauses
      - Governing law
      
      CONTRACT AGREEMENT:
    PROMPT
  end
  
  def extract_contract_content(generated_text, prompt)
    # Remove the original prompt from the generated text
    contract_content = generated_text.gsub(prompt, '').strip
    
    # Clean up any unwanted characters or formatting
    contract_content = contract_content
      .gsub(/\n{3,}/, "\n\n")  # Replace multiple newlines with double newlines
      .gsub(/^\s+/, '')        # Remove leading whitespace
      .strip
    
    # If the content is too short or doesn't look like a contract, return nil
    return nil if contract_content.length < 200 || !contract_content.include?('Agreement')
    
    contract_content
  end
  
  def format_ai_contract(ai_content)
    current_date = Date.current.strftime('%B %d, %Y')
    
    formatted_contract = <<~CONTRACT
      #{ai_content}
      
      SIGNATURE SECTION:
      
      By signing below, both parties acknowledge and agree to the terms and conditions set forth in this contract.
      
      _____________________                    _____________________
      Party A Signature                       Party B Signature
      
      Date: _______________                    Date: _______________
      
      Generated on: #{Time.current.strftime('%Y-%m-%d %H:%M:%S')}
      Generated using AI assistance based on: #{@description}
    CONTRACT
    
    formatted_contract.strip
  end
  
  def generate_contract_template
    current_date = Date.current.strftime('%B %d, %Y')
    
    contract_content = <<~CONTRACT
      CONTRACT AGREEMENT
      
      This Agreement is entered into on #{current_date} between the parties for the following purpose:
      #{@description}
      
      TERMS AND CONDITIONS:
      
      1. SCOPE OF WORK
         The service provider agrees to deliver the specified services as outlined in the contract description above.
      
      2. PAYMENT TERMS
         Payment shall be made according to the agreed schedule and terms specified during negotiations.
      
      3. DURATION
         This contract shall remain in effect for the duration specified in the agreement or until completion of services.
      
      4. RESPONSIBILITIES
         Both parties agree to fulfill their respective obligations as outlined in this agreement.
      
      5. DELIVERABLES
         Specific deliverables and milestones will be defined based on the project requirements mentioned in the description.
      
      6. INTELLECTUAL PROPERTY
         All intellectual property rights shall be clearly defined and agreed upon by both parties.
      
      7. TERMINATION
         Either party may terminate this agreement with proper notice as specified in the terms.
      
      8. GOVERNING LAW
         This agreement shall be governed by applicable laws and regulations.
      
      ADDITIONAL TERMS:
      - Confidentiality clauses apply to all sensitive information shared during the contract period
      - Any modifications to this agreement must be made in writing and signed by both parties
      - Dispute resolution procedures are outlined in the attached appendix
      
      By signing below, both parties acknowledge and agree to the terms and conditions set forth in this contract.
      
      _____________________                    _____________________
      Party A Signature                       Party B Signature
      
      Date: _______________                    Date: _______________
      
      Generated on: #{Time.current.strftime('%Y-%m-%d %H:%M:%S')}
    CONTRACT
    
    contract_content.strip
  end
  
  # Alternative method using a different Hugging Face model for better contract generation
  def call_huggingface_api_alternative(description)
    # You can try different models like:
    # - 'microsoft/DialoGPT-large' for better text generation
    # - 'gpt2' for general text generation
    # - 'facebook/blenderbot-400M-distill' for conversational AI
    
    alternative_url = 'https://api-inference.huggingface.co/models/gpt2'
    
    require 'net/http'
    require 'json'
    
    uri = URI(alternative_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{API_KEY}"
    request['Content-Type'] = 'application/json'
    
    request.body = {
      inputs: "Legal Contract for: #{description}. This agreement is between",
      parameters: {
        max_length: 800,
        temperature: 0.8,
        return_full_text: false
      }
    }.to_json
    
    response = http.request(request)
    
    if response.code == '200'
      result = JSON.parse(response.body)
      result.first['generated_text'] if result.is_a?(Array)
    else
      nil
    end
  end
end