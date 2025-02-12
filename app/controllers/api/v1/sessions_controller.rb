# app/controllers/api/v1/sessions_controller.rb
module Api
  module V1
    class SessionsController < ApplicationController
      def create
        user = User.find_by(email: params[:email])

        if user&.authenticate(params[:password])
          
          if user.activated?
            token = JsonWebToken.encode(user_id: user.id)
            render json: { 
              token: token,
              user: { id: user.id, email: user.email }
            }
          else
            render json: { 
              error: "Please activate your account first" 
            }, status: :unauthorized
          end
        else
          render json: { 
            error: "Invalid email or password" 
          }, status: :unauthorized
        end
      end
    end
  end
end