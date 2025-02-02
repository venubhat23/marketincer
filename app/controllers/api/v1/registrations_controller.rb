# app/controllers/api/v1/registrations_controller.rb
module Api
  module V1
    class RegistrationsController < ApplicationController
      def create
        user = User.new(user_params)

        if user.save
          debugger
          UserMailer.activation_email(user).deliver_later
          render json: { 
            message: "Please check your email to activate your account"
          }, status: :created
        else
          render json: { 
            errors: user.errors.full_messages 
          }, status: :unprocessable_entity
        end
      end

      def activate
        debyger
        user = User.find_by(activation_token: params[:token])

        if user && !user.activated?
          user.update(activated: true, activation_token: nil)
          render json: { 
            message: "Account activated successfully" 
          }
        else
          render json: { 
            error: "Invalid activation token" 
          }, status: :not_found
        end
      end

      private

      def user_params
        params.require(:user).permit(:email, :password, :password_confirmation)
      end
    end
  end
end