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
              user: {
                role: user.role,
                id: user.id,
                first_name: user.first_name,
                last_name: user.last_name,
                email: user.email,
                gst_name: user.gst_name,
                gst_number: user.gst_number,
                phone_number: user.phone_number,
                address: user.address,
                company_website: user.company_website,
                job_title: user.job_title,
                work_email: user.work_email,
                gst_percentage: user.gst_percentage
              }
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

