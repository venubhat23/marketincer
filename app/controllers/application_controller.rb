class ApplicationController < ActionController::API
  before_action :set_cors_headers

  # Global exception handling
  rescue_from StandardError, with: :handle_standard_error
  rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
  rescue_from ActionController::ParameterMissing, with: :handle_parameter_missing

  # Handle CORS preflight (OPTIONS) requests
  def preflight
    head :ok
  end

  # Authenticate user using Authorization header with JWT token
  def authenticate_user!
    token = request.headers['Authorization']&.split(' ')&.last
    decoded_token = JsonWebToken.decode(token)

    if decoded_token && decoded_token[:user_id]
      @current_user = User.find_by(id: decoded_token[:user_id])
      render json: { error: 'User not found' }, status: :unauthorized unless @current_user
    else
      render json: { error: 'Invalid token', decoded_token: decoded_token, token: token }, status: :unauthorized
    end
  end

  # Alternate authentication method if needed
  def authenticate_request
    header = request.headers["Authorization"]
    header = header.split(" ").last if header

    begin
      @decoded = JsonWebToken.decode(header)
      @current_user = User.find(@decoded[:user_id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: "User not found" }, status: :unauthorized
    rescue JWT::DecodeError
      render json: { error: "Invalid token" }, status: :unauthorized
    end
  end

  private

  # Error handling methods
  def handle_standard_error(exception)
    Rails.logger.error "StandardError: #{exception.message}\n#{exception.backtrace.join("\n")}"
    render json: {
      status: "error",
      message: "An unexpected error occurred",
      error: exception.message
    }, status: :internal_server_error
  end

  def handle_not_found(exception)
    render json: {
      status: "error",
      message: "Resource not found",
      error: exception.message
    }, status: :not_found
  end

  def handle_parameter_missing(exception)
    render json: {
      status: "error",
      message: "Required parameter missing",
      error: exception.message
    }, status: :bad_request
  end

  # ✅ Set CORS headers for every request
  def set_cors_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, PATCH, DELETE, OPTIONS, HEAD'
    headers['Access-Control-Allow-Headers'] = 'Origin, Content-Type, Accept, Authorization, Token'
  end
end
