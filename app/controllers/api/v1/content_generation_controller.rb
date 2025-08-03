class Api::V1::ContentGenerationController < Api::V1::BaseController
  before_action :authenticate_user!

  # POST /api/v1/generate-content
  def create
    begin
      Rails.logger.info "Content generation request received from user: #{@current_user&.id}"
      
      # Validate request parameters
      description = params[:description]
      
      if description.blank?
        return render json: {
          error: "Invalid request",
          message: "Description is required",
          code: "MISSING_DESCRIPTION"
        }, status: :bad_request
      end

      Rails.logger.info "Generating content for description: #{description}"

      # Generate content using ContentAiService
      ai_service = ContentAiService.new(description)
      generated_content = ai_service.generate

      if generated_content.present?
        Rails.logger.info "Content generation successful: #{generated_content.length} characters"
        
        # Log usage for potential rate limiting/billing
        log_content_generation(@current_user, description, generated_content)
        
        render json: {
          success: true,
          content: generated_content,
          timestamp: Time.current.iso8601,
          usage: {
            tokens_used: estimate_tokens(generated_content),
            remaining_credits: calculate_remaining_credits(@current_user)
          }
        }, status: :ok
      else
        Rails.logger.error "Content generation failed for user: #{@current_user&.id}"
        render json: {
          error: "Internal server error",
          message: "An unexpected error occurred while generating content",
          code: "GENERATION_ERROR"
        }, status: :internal_server_error
      end

    rescue StandardError => e
      Rails.logger.error "Content generation exception: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      
      render json: {
        error: "Internal server error",
        message: "An unexpected error occurred while generating content",
        code: "GENERATION_ERROR"
      }, status: :internal_server_error
    end
  end

  private

  def log_content_generation(user, description, content)
    # Log the generation for analytics/billing purposes
    Rails.logger.info "Content generated - User: #{user.id}, Description length: #{description.length}, Content length: #{content.length}"
    
    # You can store this in a database table for tracking usage
    # ContentGenerationLog.create!(
    #   user: user,
    #   description: description,
    #   generated_content: content,
    #   tokens_used: estimate_tokens(content),
    #   created_at: Time.current
    # )
  end

  def estimate_tokens(text)
    # Simple token estimation (roughly 4 characters per token)
    (text.length / 4.0).ceil
  end

  def calculate_remaining_credits(user)
    # Placeholder for credit system
    # In a real implementation, you'd check user's subscription/credits
    1000 - estimate_tokens_used_today(user)
  end

  def estimate_tokens_used_today(user)
    # Placeholder for daily usage tracking
    # You'd query your usage logs here
    150
  end
end