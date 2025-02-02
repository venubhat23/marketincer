class ApplicationController < ActionController::API

  before_action :handle_options_request

  def handle_options_request
    if request.request_method_symbol == :options
      headers["Access-Control-Allow-Origin"] = "*"
      headers["Access-Control-Allow-Methods"] = "GET, POST, PUT, PATCH, DELETE, OPTIONS"
      headers["Access-Control-Allow-Headers"] = "Content-Type, Authorization"
      head :ok
    end
  end

      def authenticate_request
      	debugger
        header = request.headers["Authorization"]
        header = header.split(" ").last if header
        debugger
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
