class ApplicationController < ActionController::API

	  def options
	    head :ok
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
