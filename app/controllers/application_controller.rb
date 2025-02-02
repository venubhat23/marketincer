class ApplicationController < ActionController::API
  before_action :set_cors_headers

   private


  def set_cors_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, PATCH, DELETE, OPTIONS, HEAD'
    headers['Access-Control-Allow-Headers'] = '*'
  end

      def authenticate_request
        header = request.headers["Authorization"]
        header = header.split(" ").last if header
        begin
          @decoded = JsonWebToken.decode(header)
          @current_user = User.find(@decoded[:user_id])
        rescue ActiveRecord::RecordNotFound
          render json: { error: "Invalid token" }, status: :unauthorized
        rescue JWT::DecodeError
          render json: { error: "Invalid token" }, status: :unauthorized
        end
      end

end
