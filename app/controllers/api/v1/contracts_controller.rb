# app/controllers/api/v1/contracts_controller.rb
class Api::V1::ContractsController < ApplicationController
  before_action :set_contract, only: [:show, :update, :destroy, :duplicate, :regenerate_ai_contract]

  # GET /api/v1/contracts
  def index
    @contracts = Contract.includes(:ai_generation_logs).recent
    @contracts = @contracts.search_by_name(params[:search]) if params[:search].present?
    @contracts = @contracts.by_status(params[:status]) if params[:status].present?
    @contracts = @contracts.by_type(params[:contract_type]) if params[:contract_type].present?
    
    # Get total count before pagination
    total_count = @contracts.count
    
    @contracts = @contracts.page(params[:page] || 1).per(params[:per_page] || 10)

    # Preload AI generation logs for determining contract type
    ai_logs_by_contract = @contracts.each_with_object({}) do |contract, hash|
      hash[contract.id] = contract.ai_generation_logs.any?
    end

    render json: {
      success: true,
      contracts: @contracts.map { |c| contract_summary(c, ai_logs_by_contract[c.id]) },
      total: total_count
    }
  end

  # GET /api/v1/contracts/templates
  def templates
    # Use class variable to cache templates to avoid repeated generation
    @templates ||= Contract.contract_templates
    render json: { 
      success: true, 
      templates: @templates.map { |t| template_summary(t) }, 
      count: @templates.length 
    }
  end

  # GET /api/v1/contracts/:id
  def show
    render json: { success: true, contract: contract_detail(@contract) }
  end

  # POST /api/v1/contracts
  def create
    @contract = Contract.new(contract_params)
    @contract.date_created ||= Date.current
    @contract.status = :draft if @contract.status.nil?
    
    if params[:contract]["status"] == "draft"
       @contract.status = 1
    end
    
    if @contract.save
      render json: { 
        success: true, 
        contract: contract_detail(@contract),
        message: 'Contract created successfully'
      }, status: :created
    else
      render json: { 
        success: false, 
        message: @contract.errors.full_messages.join(', '),
        errors: @contract.errors
      }, status: :unprocessable_entity
    end
  end

  # PUT/PATCH /api/v1/contracts/:id
  def update
    # Handle different update actions based on the action parameter
    case params[:action_type]
    when 'save_draft'
      update_contract_draft
    when 'save_contract'
      update_contract_signed
    else
      update_contract_general
    end
  end

  # DELETE /api/v1/contracts/:id
  def destroy
    @contract.destroy
    render json: { success: true, message: 'Contract deleted successfully' }
  end

  # POST /api/v1/contracts/:id/duplicate
  def duplicate
    copy = @contract.dup
    copy.name = "#{@contract.name} (Copy)"
    copy.status = :draft
    copy.action = 'pending'
    copy.date_created = Date.current
    
    if copy.save
      render json: { 
        success: true, 
        contract: contract_detail(copy),
        message: 'Contract duplicated successfully'
      }
    else
      render json: { 
        success: false, 
        message: copy.errors.full_messages.join(', ') 
      }, status: :unprocessable_entity
    end
  end

  # POST /api/v1/contracts/generate
  def generate_ai_contract
    description = params[:description]&.strip
    template_id = params[:template_id]
    use_template = params[:use_template] == 'true' || params[:use_template] == true
    save_contract = params[:save_contract] == 'true' || params[:save_contract] == true

    # Enhanced validation
    if use_template && template_id.blank?
      return render json: { 
        success: false, 
        message: 'Template ID is required when using template generation' 
      }, status: :bad_request
    end

    if !use_template && description.blank?
      return render json: { 
        success: false, 
        message: 'Description is required for AI contract generation' 
      }, status: :bad_request
    end

    # Validate description length and content
    if description.present? && description.length < 10
      return render json: { 
        success: false, 
        message: 'Description must be at least 10 characters long' 
      }, status: :bad_request
    end

    begin
      Rails.logger.info "Contract generation request: template=#{use_template}, description=#{description&.truncate(100)}"
      
      if use_template && template_id.present?
        # Generate from template
        result = generate_from_template(template_id, save_contract)
      elsif description.present?
        # Generate using AI
        result = generate_from_ai(description, nil, save_contract)
      else
        return render json: { 
          success: false, 
          message: 'Either description or template_id is required' 
        }, status: :bad_request
      end

      if result[:success]
        response_data = {
          success: true,
          message: result[:message],
          contract_type: result[:contract_type],
          generation_method: result[:generation_method],
          ai_log: result[:ai_log]
        }
        
        # Include contract content if available (for direct AI responses)
        if result[:contract_content]
          response_data[:contract_content] = result[:contract_content]
        end
        
        # Include contract data if it was saved
        if result[:contract]
          response_data[:contract] = contract_detail(result[:contract])
        end
        
        render json: response_data
      else
        render json: {
          success: false,
          message: result[:message],
          error_code: result[:error_code]
        }, status: :unprocessable_entity
      end

    rescue StandardError => e
      Rails.logger.error "Contract generation failed: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      
      render json: {
        success: false,
        message: 'Contract generation failed due to an internal error. Please try again.',
        error: Rails.env.development? ? e.message : 'Internal server error'
      }, status: :internal_server_error
    end
  end

  # POST /api/v1/contracts/:id/regenerate
  def regenerate_ai_contract
    description = params[:description]&.strip || @contract.description

    if description.blank?
      return render json: { 
        success: false, 
        message: 'Description is required for contract regeneration' 
      }, status: :bad_request
    end

    if description.length < 10
      return render json: { 
        success: false, 
        message: 'Description must be at least 10 characters long' 
      }, status: :bad_request
    end

    begin
      Rails.logger.info "Contract regeneration request for contract #{@contract.id}"
      
      result = generate_from_ai(description, @contract, true)
      
      if result[:success]
        render json: {
          success: true,
          contract: contract_detail(result[:contract]),
          message: result[:message],
          generation_method: result[:generation_method]
        }
      else
        render json: {
          success: false,
          message: result[:message],
          error_code: result[:error_code]
        }, status: :unprocessable_entity
      end

    rescue StandardError => e
      Rails.logger.error "Contract regeneration failed: #{e.message}"
      render json: {
        success: false,
        message: 'Contract regeneration failed due to an internal error. Please try again.',
        error: Rails.env.development? ? e.message : 'Internal server error'
      }, status: :internal_server_error
    end
  end

  # GET /api/v1/contracts/ai_status
  def ai_generation_status
    contract_id = params[:contract_id]
    
    if contract_id.present?
      logs = AiGenerationLog.includes(:contract).for_contract(contract_id).recent.limit(5)
    else
      logs = AiGenerationLog.includes(:contract).recent.limit(10)
    end

    render json: {
      success: true,
      ai_logs: logs.map { |log| ai_log_summary(log) }
    }
  end

  private

  def set_contract
    @contract = Contract.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { success: false, message: 'Contract not found' }, status: :not_found
  end

  def contract_params
    params.require(:contract).permit(
      :name, :description, :content, :contract_type, :status, 
      :category, :action, :date_created, metadata: {}
    )
  end

  def update_contract_draft
    @contract.assign_attributes(contract_params)
    @contract.status = :draft
    @contract.action = 'draft'

    if @contract.save
      render json: { 
        success: true, 
        contract: contract_detail(@contract),
        message: 'Contract saved as draft successfully'
      }
    else
      render json: { 
        success: false, 
        message: @contract.errors.full_messages.join(', ') 
      }, status: :unprocessable_entity
    end
  end

  def update_contract_signed
    @contract.assign_attributes(contract_params)
    @contract.status = :signed
    @contract.action = 'signed'

    if @contract.save
      render json: { 
        success: true, 
        contract: contract_detail(@contract),
        message: 'Contract saved and marked as signed successfully'
      }
    else
      render json: { 
        success: false, 
        message: @contract.errors.full_messages.join(', ') 
      }, status: :unprocessable_entity
    end
  end

  def update_contract_general
    if @contract.update(contract_params)
      render json: { 
        success: true, 
        contract: contract_detail(@contract),
        message: 'Contract updated successfully'
      }
    else
      render json: { 
        success: false, 
        message: @contract.errors.full_messages.join(', ') 
      }, status: :unprocessable_entity
    end
  end

  def generate_from_template(template_id, save_contract = false)
    # Use cached templates instead of calling class method repeatedly
    @templates ||= Contract.contract_templates
    template = @templates.find { |t| t[:id].to_s == template_id.to_s }
    
    unless template
      return { 
        success: false, 
        message: 'Template not found',
        error_code: 'TEMPLATE_NOT_FOUND'
      }
    end

    contract_data = {
      name: template[:name],
      description: template[:description],
      contract_type: Contract::CONTRACT_TYPES[template[:contract_type].to_sym],
      category: Contract::CATEGORIES[template[:category].to_sym],
      content: template[:template],
      status: :draft,
      action: 'draft',
      date_created: Date.current
    }

    if save_contract
      contract = Contract.new(contract_data)
      if contract.save
        return { 
          success: true, 
          contract: contract, 
          message: 'Contract generated from template and saved successfully',
          generation_method: 'template',
          contract_type: template[:contract_type]
        }
      else
        return { 
          success: false, 
          message: contract.errors.full_messages.join(', '),
          error_code: 'TEMPLATE_SAVE_FAILED'
        }
      end
    else
      # Return template data without saving
      return { 
        success: true, 
        template_data: contract_data,
        message: 'Contract template generated successfully',
        generation_method: 'template',
        contract_type: template[:contract_type]
      }
    end
  end

  def generate_from_ai(description, existing_contract = nil, save_contract = false)
    # Create AI generation log
    ai_log = AiGenerationLog.create!(
      description: description,
      status: AiGenerationLog::STATUS_PENDING,
      contract: existing_contract
    )

    Rails.logger.info "Starting direct AI generation with log ID: #{ai_log.id}"

    begin
      ai_log.update!(status: AiGenerationLog::STATUS_PROCESSING)
      
      # DIRECT AI GENERATION - Send description directly to AI
      ai_service = AiContractGenerationService.new(description)
      ai_response = ai_service.generate

      if ai_response.blank?
        ai_log.update!(
          status: AiGenerationLog::STATUS_FAILED,
          error_message: 'AI service returned empty response'
        )
        return { 
          success: false, 
          message: 'AI failed to generate response. Please try again with a different description.',
          error_code: 'AI_GENERATION_EMPTY',
          ai_log: ai_log_summary(ai_log)
        }
      end

      # Save the contract if requested
      if existing_contract
        # Update existing contract
        existing_contract.update!(
          content: ai_response,
          description: description,
          status: :draft
        )
        contract = existing_contract
      elsif save_contract
        # Create new contract
        contract = Contract.create!(
          name: "AI Generated Contract - #{Date.current.strftime('%B %Y')}",
          description: description,
          content: ai_response,
          status: :draft,
          action: 'draft',
          date_created: Date.current
        )
      end

      # Update AI log with success
      ai_log.update!(
        status: AiGenerationLog::STATUS_COMPLETED,
        generated_content: ai_response,
        contract: contract
      )

      Rails.logger.info "Direct AI generation completed successfully"

      response_data = { 
        success: true, 
        message: 'AI response generated successfully',
        generation_method: 'direct_ai',
        contract_content: ai_response,
        ai_log: ai_log_summary(ai_log)
      }

      response_data[:contract] = contract_detail(contract) if contract

      return response_data

    rescue StandardError => e
      # Update AI log with failure
      ai_log.update!(
        status: AiGenerationLog::STATUS_FAILED,
        error_message: e.message
      )
      
      Rails.logger.error "Direct AI generation failed: #{e.message}"
      
      return { 
        success: false, 
        message: "AI generation failed: #{e.message}",
        error_code: 'AI_GENERATION_ERROR',
        ai_log: ai_log_summary(ai_log)
      }
    end
  end

  def generate_contract_name(description, contract_type, entities = {})
    name_parts = []
    
    # Use extracted companies/brands if available
    if entities[:companies]&.any?
      name_parts << entities[:companies].first
    elsif entities[:parties]&.any?
      name_parts << entities[:parties].first
    elsif description.match?(/nike/i)
      name_parts << "Nike"
    elsif description.match?(/influencer/i)
      name_parts << "Influencer"
    end
    
    # Add contract type
    name_parts << contract_type
    
    # Add date
    name_parts << Date.current.strftime('%B %Y')
    
    # If we have meaningful parts, join them, otherwise use a default
    if name_parts.size >= 2
      name_parts.join(' - ')
    else
      "AI Generated #{contract_type} - #{Date.current.strftime('%B %Y')}"
    end
  end

  def determine_contract_type_from_content(content)
    content_lower = content.to_s.downcase
    
    case content_lower
    when /non-disclosure|nda|confidential/
      { type_name: 'Non-Disclosure Agreement', type_id: Contract::CONTRACT_TYPES[:nda], category_id: Contract::CATEGORIES[:vendor] }
    when /influencer|social media|brand collaboration/
      { type_name: 'Influencer Collaboration', type_id: Contract::CONTRACT_TYPES[:collaboration], category_id: Contract::CATEGORIES[:influencer] }
    when /sponsorship|sponsor/
      { type_name: 'Sponsorship Agreement', type_id: Contract::CONTRACT_TYPES[:sponsorship], category_id: Contract::CATEGORIES[:brand] }
    when /employment|job|hiring/
      { type_name: 'Employment Contract', type_id: Contract::CONTRACT_TYPES[:employment], category_id: Contract::CATEGORIES[:employee] }
    when /gift|product/
      { type_name: 'Gifting Agreement', type_id: Contract::CONTRACT_TYPES[:gifting], category_id: Contract::CATEGORIES[:influencer] }
    else
      { type_name: 'Service Agreement', type_id: Contract::CONTRACT_TYPES[:service], category_id: Contract::CATEGORIES[:freelancer] }
    end
  end

  # Optimized contract_summary method - accepts preloaded ai_log flag
  def contract_summary(contract, has_ai_logs = nil)
    {
      id: contract.id,
      name: contract.name,
      type: determine_contract_type(contract, has_ai_logs),
      type_id: contract.contract_type,
      status: determine_contract_status(contract),
      status_id: contract.status,
      category: contract.category_sym,
      category_id: contract.category,
      date_created: contract.date_created || contract.created_at&.to_date,
      action: contract.action,
      description: contract.description&.truncate(100),
      has_content: contract.content.present?,
      created_at: contract.created_at,
      updated_at: contract.updated_at
    }
  end

  def template_summary(template)
    {
      id: template[:id],
      name: template[:name],
      type: template[:contract_type]&.to_s&.titleize,
      date_created: template[:created_at] || Date.current,
      description: template[:description],
      template_content: template[:template]
    }
  end

  # Optimized to accept preloaded ai_log flag to avoid N+1 queries
  def determine_contract_type(contract, has_ai_logs = nil)
    # Use preloaded flag if available, otherwise fallback to query
    if has_ai_logs.nil?
      has_ai_logs = contract.ai_generation_logs.any?
    end
    
    if contract.content.present? && has_ai_logs
      'AI Generated'
    else
      'Template'
    end
  end

  def determine_contract_status(contract)
    case contract.status&.to_s&.downcase
    when 'draft'
      'Draft'
    when 'completed', 'signed', 'active'
      'Completed'
    else
      contract.status&.to_s&.titleize || 'Draft'
    end
  end

  def contract_detail(contract)
    contract_summary(contract).merge(
      content: contract.content,
      full_description: contract.description,
      metadata: contract.metadata
    )
  end

  def ai_log_summary(log)
    {
      id: log.id,
      contract_id: log.contract_id,
      description: log.description,
      status: log.status,
      error_message: log.error_message,
      has_content: log.generated_content.present?,
      created_at: log.created_at,
      updated_at: log.updated_at
    }
  end

  def build_generation_success_message(entities, action, contract_type)
    base_message = "#{contract_type} #{action} successfully"
    
    entity_parts = []
    
    if entities[:parties]&.any?
      parties = entities[:parties].join(' and ')
      entity_parts << "between #{parties}"
    end
    
    if entities[:amounts]&.any?
      amount = entities[:amounts].first
      entity_parts << "for #{amount}"
    end
    
    if entities[:dates]&.any?
      date = entities[:dates].first
      entity_parts << "effective #{date}"
    end
    
    if entities[:companies]&.any?
      companies = entities[:companies].join(' and ')
      entity_parts << "involving #{companies}"
    end
    
    if entity_parts.any?
      "#{base_message} #{entity_parts.join(', ')}. I've automatically extracted and incorporated the key details from your request."
    else
      "#{base_message}. The contract has been generated based on your description."
    end
  end

  def format_entities_for_response(entities)
    return {} if entities.blank?
    
    formatted = {}
    
    entities.each do |key, values|
      next if values.blank?
      formatted[key] = values.is_a?(Array) ? values : [values]
    end
    
    formatted
  end
end