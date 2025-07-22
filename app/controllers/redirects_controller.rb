class RedirectsController < ApplicationController
  before_action :set_short_url, only: [:show]

  # GET /r/:short_code
  def show
    if @short_url&.active?
      # Track the click
      track_click(@short_url, request)
      
      # Increment click counter
      @short_url.increment_clicks!
      
      # Redirect to the original URL
      redirect_to @short_url.long_url, status: :moved_permanently, allow_other_host: true
    else
      render json: { 
        error: "Short URL not found or inactive",
        message: "The requested short URL does not exist or has been deactivated"
      }, status: :not_found
    end
  end

  # GET /r/:short_code/preview
  def preview
    if @short_url&.active?
      render json: {
        short_code: @short_url.short_code,
        short_url: @short_url.short_url,
        long_url: @short_url.long_url,
        title: @short_url.title || "Shortened URL",
        description: @short_url.description || "This link will redirect you to: #{@short_url.long_url}",
        clicks: @short_url.clicks,
        created_at: @short_url.created_at.iso8601,
        warning: "You are about to be redirected to an external website. Please verify the URL is safe before proceeding."
      }
    else
      render json: { 
        error: "Short URL not found or inactive" 
      }, status: :not_found
    end
  end

  # GET /r/:short_code/info
  def info
    if @short_url&.active?
      render json: {
        short_code: @short_url.short_code,
        short_url: @short_url.short_url,
        long_url: @short_url.long_url,
        title: @short_url.title,
        description: @short_url.description,
        clicks: @short_url.clicks,
        created_at: @short_url.created_at.iso8601,
        qr_code_url: generate_qr_code_url(@short_url.short_url)
      }
    else
      render json: { 
        error: "Short URL not found or inactive" 
      }, status: :not_found
    end
  end

  private

  def set_short_url
    @short_url = ShortUrl.find_by(short_code: params[:short_code])
  end

  def track_click(short_url, request)
    # Create click analytics record in background
    begin
      ClickAnalytic.create_from_request(short_url, request)
    rescue => e
      # Log error but don't fail the redirect
      Rails.logger.error "Failed to track click: #{e.message}"
    end
  end

  def generate_qr_code_url(url)
    # Using Google Charts API for QR code generation
    # In production, you might want to use a dedicated QR code service
    encoded_url = CGI.escape(url)
    "https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=#{encoded_url}"
  end
end