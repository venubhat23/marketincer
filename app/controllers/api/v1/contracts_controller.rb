class Api::V1::ContractsController < ApplicationController
  before_action :set_contract, only: [:show, :update, :destroy]
  
  # GET /api/v1/contracts
  def index
    @contracts = Contract.all
    
    # Filter by category (templates or created contracts)
    @contracts = @contracts.templates_only if params[:category] == 'template'
    @contracts = @contracts.contracts_only if params[:category] == 'created'
    
    # Search functionality
    @contracts = @contracts.search_by_name(params[:search]) if params[:search].present?
    
    # Pagination
    page = params[:page] || 1
    per_page = params[:per_page] || 20
    @contracts = @contracts.page(page).per(per_page)
    
    render json: {
      contracts: @contracts.map { |contract| contract_json(contract) },
      total_count: @contracts.total_count,
      current_page: @contracts.current_page,
      total_pages: @contracts.total_pages,
      stats: {
        total_contracts: Contract.contracts_only.count,
        total_templates: Contract.templates_only.count
      }
    }
  end
  
  # GET /api/v1/contracts/:id
  def show
    render json: { contract: contract_json(@contract) }
  end
  
  # POST /api/v1/contracts
  def create
    @contract = Contract.new(contract_params)
    
    if @contract.save
      render json: { 
        contract: contract_json(@contract),
        message: 'Contract created successfully'
      }, status: :created
    else
      render json: { error: @contract.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  # PATCH/PUT /api/v1/contracts/:id
  def update
    if @contract.update(contract_params)
      render json: { 
        contract: contract_json(@contract),
        message: 'Contract updated successfully'
      }
    else
      render json: { error: @contract.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  # DELETE /api/v1/contracts/:id
  def destroy
    @contract.destroy
    render json: { message: 'Contract deleted successfully' }
  end
  
  # GET /api/v1/contracts/templates
  def templates
    @templates = Contract.templates_only.order(:name)
    
    render json: {
      templates: @templates.map { |template| contract_json(template) }
    }
  end
  
  # POST /api/v1/contracts/:id/duplicate
  def duplicate
    @original_contract = Contract.find(params[:id])
    @new_contract = @original_contract.dup
    @new_contract.name = "#{@original_contract.name} (Copy)"
    @new_contract.status = 'draft'
    @new_contract.category = 'created'
    
    if @new_contract.save
      render json: { 
        contract: contract_json(@new_contract),
        message: 'Contract duplicated successfully'
      }, status: :created
    else
      render json: { error: @new_contract.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  # POST /api/v1/contracts/generate
  def generate_ai_contract
    description = params[:description]
    contract_type = params[:contract_type] || 'service_agreement'
    name = params[:name] || "AI Generated Contract - #{Date.current.strftime('%m/%d/%Y')}"
    
    if description.blank?
      render json: { error: 'Description is required for AI contract generation' }, status: :bad_request
      return
    end
    
    begin
      # Generate contract using AI service
      ai_service = AiContractGenerationService.new(description)
      generated_content = ai_service.generate
      
      # Create new contract with AI-generated content
      @contract = Contract.new(
        name: name,
        contract_type: contract_type,
        status: 'draft',
        category: 'created',
        content: generated_content,
        description: description,
        metadata: {
          generated_by: 'ai',
          generation_method: 'huggingface_api',
          generated_at: Time.current,
          original_description: description
        }
      )
      
      if @contract.save
        render json: {
          contract: contract_json(@contract),
          message: 'AI contract generated successfully',
          ai_generated: true
        }, status: :created
      else
        render json: { error: @contract.errors.full_messages }, status: :unprocessable_entity
      end
      
    rescue => e
      Rails.logger.error "AI Contract Generation Error: #{e.message}"
      render json: { 
        error: 'Failed to generate AI contract. Please try again or use manual creation.',
        details: Rails.env.development? ? e.message : nil
      }, status: :internal_server_error
    end
  end
  
  # POST /api/v1/contracts/:id/regenerate
  def regenerate_ai_contract
    @contract = Contract.find(params[:id])
    
    # Check if contract has original description for regeneration
    original_description = @contract.metadata&.dig('original_description') || @contract.description
    
    if original_description.blank?
      render json: { error: 'Cannot regenerate contract without original description' }, status: :bad_request
      return
    end
    
    begin
      # Regenerate content using AI service
      ai_service = AiContractGenerationService.new(original_description)
      regenerated_content = ai_service.generate
      
      # Update contract with new content
      @contract.update!(
        content: regenerated_content,
        metadata: @contract.metadata.merge({
          regenerated_at: Time.current,
          regeneration_count: (@contract.metadata['regeneration_count'] || 0) + 1
        })
      )
      
      render json: {
        contract: contract_json(@contract),
        message: 'Contract regenerated successfully',
        regenerated: true
      }
      
    rescue => e
      Rails.logger.error "AI Contract Regeneration Error: #{e.message}"
      render json: { 
        error: 'Failed to regenerate contract. Please try again.',
        details: Rails.env.development? ? e.message : nil
      }, status: :internal_server_error
    end
  end
  
  # GET /api/v1/contracts/ai_status
  def ai_generation_status
    render json: {
      ai_enabled: true,
      service: 'Hugging Face API',
      models_available: [
        'microsoft/DialoGPT-medium',
        'gpt2',
        'facebook/blenderbot-400M-distill'
      ],
      features: [
        'AI contract generation',
        'Contract regeneration',
        'Fallback to templates',
        'Error handling'
      ]
    }
  end
  
  private
  
  def set_contract
    @contract = Contract.find(params[:id])
  end
  
  def contract_params
    params.require(:contract).permit(:name, :contract_type, :status, :category, :content, :description, metadata: {})
  end
  
  def contract_json(contract)
    binding.pry
    {
      id: contract.id,
      name: contract.name,
      type: contract.contract_type,
      status: contract.status,
      category: contract.category,
      date_created: contract.date_created&.strftime('%b %d, %Y'),
      action: contract.action.titleize,
      content: contract.content,
      description: contract.description,
      metadata: contract.metadata,
      ai_generated: contract.metadata&.dig('generated_by') == 'ai',
      can_regenerate: contract.metadata&.dig('original_description').present?,
      created_at: contract.created_at,
      updated_at: contract.updated_at
    }
  end
end