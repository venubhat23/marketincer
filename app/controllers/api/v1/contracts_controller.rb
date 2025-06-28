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
    description = params[:description]
    template_id = params[:template_id]
    use_template = params[:use_template] == 'true' || params[:use_template] == true

    begin
      if use_template && template_id.present?
        # Generate from template
        result = generate_from_template(template_id)
      elsif description.present?
        # Generate using AI
        result = generate_from_ai(description)
      else
        return render json: { 
          success: false, 
          message: 'Description is required for AI generation or template_id for template usage' 
        }, status: :bad_request
      end

      if result[:success]
        render json: {
          success: true,
          ai_log: result[:ai_log],
          message: result[:message]
        }
      else
        render json: {
          success: false,
          message: result[:message]
        }, status: :unprocessable_entity
      end

    rescue StandardError => e
      Rails.logger.error "Contract generation failed: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      
      render json: {
        success: false,
        message: 'Contract generation failed. Please try again.',
        error: e.message
      }, status: :internal_server_entity
    end
  end

  # POST /api/v1/contracts/:id/regenerate
  def regenerate_ai_contract
    description = params[:description] || @contract.description

    return render json: { 
      success: false, 
      message: 'Description is required for regeneration' 
    }, status: :bad_request if description.blank?

    begin
      result = generate_from_ai(description, @contract)
      
      if result[:success]
        render json: {
          success: true,
          contract: contract_detail(result[:contract]),
          message: 'Contract regenerated successfully'
        }
      else
        render json: {
          success: false,
          message: result[:message]
        }, status: :unprocessable_entity
      end

    rescue StandardError => e
      Rails.logger.error "Contract regeneration failed: #{e.message}"
      render json: {
        success: false,
        message: 'Contract regeneration failed. Please try again.'
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

  def generate_from_template(template_id)
    # Use cached templates instead of calling class method repeatedly
    @templates ||= Contract.contract_templates
    template = @templates.find { |t| t[:id].to_s == template_id.to_s }
    
    unless template
      return { success: false, message: 'Template not found' }
    end

    contract = Contract.new(
      name: template[:name],
      description: template[:description],
      contract_type: Contract::CONTRACT_TYPES[template[:contract_type].to_sym],
      category: Contract::CATEGORIES[template[:category].to_sym],
      content: template[:template],
      status: :draft,
      action: 'draft',
      date_created: Date.current
    )

    if contract.save
      { success: true, contract: contract, message: 'Contract generated from template successfully' }
    else
      { success: false, message: contract.errors.full_messages.join(', ') }
    end
  end

  def generate_from_ai(description, existing_contract = nil)
    # Log the AI generation attempt
    ai_log = AiGenerationLog.create!(
      description: description,
      status: AiGenerationLog::STATUS_PENDING
    )

    begin
      ai_log.update!(status: AiGenerationLog::STATUS_PROCESSING)
      
      # Generate content using AI service
      ai_service = AiContractGenerationService.new(description)
      ai_contract_content = ai_service.generate

      if existing_contract
        # Update existing contract
        existing_contract.update!(
          content: ai_contract_content,
          description: description,
          status: :draft
        )
        contract = existing_contract
      else
        # Create new contract
        # contract = Contract.create!(
        #   name: "AI Generated - #{description.truncate(50)}",
        #   description: description,
        #   contract_type: Contract::CONTRACT_TYPES[:service],
        #   category: Contract::CATEGORIES[:freelancer],
        #   content: ai_contract_content,
        #   status: 1,
        #   action: 'draft',
        #   date_created: Date.current
        # )
      end

      # Update AI log with success
      ai_log.update!(
        status: AiGenerationLog::STATUS_COMPLETED,
        generated_content: ai_contract_content,
      )

      { success: true, ai_log: ai_log, message: 'AI contract generated successfully' }

    rescue StandardError => e
      # Update AI log with failure
      ai_log.update!(
        status: AiGenerationLog::STATUS_FAILED,
        error_message: e.message
      )
      
      { success: false, message: "AI generation failed: #{e.message}" }
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
end