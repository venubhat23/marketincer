class Api::V1::ShortUrlsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_short_url, only: [:show, :update, :destroy]

  # POST /api/v1/shorten
  def create
    @short_url = current_user.short_urls.build(short_url_params)

    if @short_url.save
      render json: {
        short_url: @short_url.short_url,
        long_url: @short_url.long_url,
        short_code: @short_url.short_code,
        clicks: @short_url.clicks,
        message: "URL shortened successfully",
        created_at: @short_url.created_at.iso8601
      }, status: :created
    else
      render json: {
        errors: @short_url.errors.full_messages,
        message: "Failed to shorten URL"
      }, status: :unprocessable_entity
    end
  end

  # GET /api/v1/users/:user_id/urls
  def index
    @short_urls = current_user.short_urls.active.recent.page(params[:page]).per(20)
    
    render json: {
      user_id: current_user.id,
      total_links: current_user.short_urls.active.count,
      total_clicks: current_user.total_clicks,
      page: params[:page] || 1,
      per_page: 20,
      urls: @short_urls.map do |short_url|
        {
          id: short_url.id,
          long_url: short_url.long_url,
          short_url: short_url.short_url,
          short_code: short_url.short_code,
          clicks: short_url.clicks,
          title: short_url.title,
          description: short_url.description,
          active: short_url.active,
          created_at: short_url.created_at.iso8601
        }
      end
    }
  end

  # GET /api/v1/short_urls/:id
  def show
    render json: {
      id: @short_url.id,
      long_url: @short_url.long_url,
      short_url: @short_url.short_url,
      short_code: @short_url.short_code,
      clicks: @short_url.clicks,
      title: @short_url.title,
      description: @short_url.description,
      active: @short_url.active,
      created_at: @short_url.created_at.iso8601,
      analytics: {
        clicks_today: @short_url.clicks_today,
        clicks_this_week: @short_url.clicks_this_week,
        clicks_this_month: @short_url.clicks_this_month,
        clicks_by_country: @short_url.clicks_by_country,
        clicks_by_device: @short_url.clicks_by_device,
        clicks_by_browser: @short_url.clicks_by_browser
      }
    }
  end

  # PATCH/PUT /api/v1/short_urls/:id
  def update
    if @short_url.update(update_params)
      render json: {
        id: @short_url.id,
        long_url: @short_url.long_url,
        short_url: @short_url.short_url,
        short_code: @short_url.short_code,
        clicks: @short_url.clicks,
        title: @short_url.title,
        description: @short_url.description,
        active: @short_url.active,
        message: "Short URL updated successfully",
        updated_at: @short_url.updated_at.iso8601
      }
    else
      render json: {
        errors: @short_url.errors.full_messages,
        message: "Failed to update short URL"
      }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/short_urls/:id
  def destroy
    @short_url.update(active: false)
    render json: {
      message: "Short URL deactivated successfully"
    }
  end

  # GET /api/v1/users/:user_id/dashboard
  def dashboard
    render json: {
      user_id: current_user.id,
      total_urls: current_user.total_short_urls,
      total_clicks: current_user.total_clicks,
      urls_created_this_month: current_user.urls_created_this_month,
      recent_urls: current_user.short_urls.active.recent.limit(5).map do |short_url|
        {
          id: short_url.id,
          long_url: short_url.long_url,
          short_url: short_url.short_url,
          clicks: short_url.clicks,
          created_at: short_url.created_at.iso8601
        }
      end,
      top_performing_urls: current_user.short_urls.active.order(clicks: :desc).limit(5).map do |short_url|
        {
          id: short_url.id,
          long_url: short_url.long_url,
          short_url: short_url.short_url,
          clicks: short_url.clicks,
          created_at: short_url.created_at.iso8601
        }
      end
    }
  end

  private

  def set_short_url
    @short_url = current_user.short_urls.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Short URL not found" }, status: :not_found
  end

  def short_url_params
    params.require(:short_url).permit(:long_url, :title, :description)
  end

  def update_params
    params.require(:short_url).permit(:title, :description, :active)
  end

  def authenticate_user!
    token = request.headers['Authorization']&.split(' ')&.last
    
    if token.blank?
      render json: { error: "Authorization token required" }, status: :unauthorized
      return
    end

    begin
      decoded_token = JWT.decode(token, Rails.application.secret_key_base, true, algorithm: 'HS256')
      user_id = decoded_token[0]['user_id']
      @current_user = User.find(user_id)
    rescue JWT::DecodeError, ActiveRecord::RecordNotFound
      render json: { error: "Invalid or expired token" }, status: :unauthorized
    end
  end

  def current_user
    @current_user
  end
end