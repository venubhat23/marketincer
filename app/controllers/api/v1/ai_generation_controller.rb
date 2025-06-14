class Api::V1::AiGenerationController < ApplicationController
  
  # POST /api/v1/ai-generation/generate
  def generate
    description = params[:description]
    
    if description.blank?
      return render json: { error: 'Description is required' }, status: :bad_request
    end

    # Log the generation request
    @ai_log = AiGenerationLog.create!(
      description: description,
      status: 'processing'
    )

    begin
      # Call AI service
      generated_content = AiContractGenerationService.new(description).generate
      
      @ai_log.update!(
        generated_content: generated_content,
        status: 'completed'
      )
      
      render json: {
        content: generated_content,
        generation_id: @ai_log.id,
        message: 'Contract generated successfully'
      }
      
    rescue => e
      @ai_log.update!(
        status: 'failed',
        error_message: e.message
      )
      
      render json: { 
        error: 'Failed to generate contract', 
        details: e.message 
      }, status: :internal_server_error
    end
  end
  
  # POST /api/v1/ai-generation/save-draft
  def save_draft
    contract_data = params.require(:contract).permit(:name, :content, :description, :contract_type)
    generation_id = params[:generation_id]
    
    @contract = Contract.new(
      name: contract_data[:name] || "Draft Contract #{Time.current.strftime('%Y%m%d%H%M%S')}",
      content: contract_data[:content],
      description: contract_data[:description],
      contract_type: contract_data[:contract_type] || 'collaboration',
      status: 'draft',
      category: 'created'
    )
    
    if @contract.save
      # Link with AI generation log if provided
      if generation_id.present?
        ai_log = AiGenerationLog.find_by(id: generation_id)
        ai_log&.update(contract: @contract)
      end
      
      render json: {
        contract: contract_json(@contract),
        message: 'Draft saved successfully'
      }, status: :created
    else
      render json: { error: @contract.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  private
  
  def contract_json(contract)
    {
      id: contract.id,
      name: contract.name,
      type: contract.contract_type.titleize,
      status: contract.status.titleize,
      category: contract.category,
      date_created: contract.date_created&.strftime('%b %d, %Y'),
      action: contract.action.titleize,
      content: contract.content,
      description: contract.description,
      created_at: contract.created_at,
      updated_at: contract.updated_at
    }
  end
end
