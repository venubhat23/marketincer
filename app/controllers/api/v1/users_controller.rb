module Api
  module V1
    class UsersController < ApplicationController
      before_action :authenticate_user!  # Make sure user is logged in

      def update_profile
        if @current_user.update(user_params)
          render json: { message: "Profile updated successfully", user: @current_user }, status: :ok
        else
          render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def user_params
        params.require(:user).permit(
          :first_name,
          :last_name,
          :gst_name,
          :gst_number,
          :phone_number,
          :address,
          :company_website,
          :job_title,
          :work_email,
          :gst_percentage
        )
      end
    end
  end
end
