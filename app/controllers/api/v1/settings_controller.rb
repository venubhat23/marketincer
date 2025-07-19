module Api
  module V1
    class SettingsController < ApplicationController
      before_action :authenticate_user!

      # GET /api/v1/settings - Get all settings
      def index
        render json: {
          status: "success",
          data: {
            personal_information: {
              first_name: @current_user.first_name,
              last_name: @current_user.last_name,
              email: @current_user.email,
              phone_number: @current_user.phone_number,
              bio: @current_user.bio,
              avatar_url: @current_user.avatar_url
            },
            company_details: {
              name: @current_user.company_name,
              gst_name: @current_user.gst_name,
              gst_number: @current_user.gst_number,
              phone_number: @current_user.phone_number,
              address: @current_user.address,
              website: @current_user.company_website
            }
          }
        }, status: :ok
      end

      # PATCH /api/v1/settings/personal_information - Update personal info
      def update_personal_information
        if @current_user.update(personal_information_params)
          render json: {
            status: "success",
            message: "Personal information updated successfully",
            data: {
              first_name: @current_user.first_name,
              last_name: @current_user.last_name,
              email: @current_user.email,
              phone_number: @current_user.phone_number,
              bio: @current_user.bio,
              avatar_url: @current_user.avatar_url
            }
          }, status: :ok
        else
          render json: {
            status: "error",
            message: "Failed to update personal information",
            errors: @current_user.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/settings/company_details - Update company details
      def update_company_details
        if @current_user.update(company_details_params)
          render json: {
            status: "success",
            message: "Company details updated successfully",
            data: {
              name: @current_user.company_name,
              gst_name: @current_user.gst_name,
              gst_number: @current_user.gst_number,
              phone_number: @current_user.phone_number,
              address: @current_user.address,
              website: @current_user.company_website
            }
          }, status: :ok
        else
          render json: {
            status: "error",
            message: "Failed to update company details",
            errors: @current_user.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/settings/change_password - Change password
      def change_password
        unless @current_user.authenticate(password_params[:current_password])
          return render json: {
            status: "error",
            message: "Current password is incorrect"
          }, status: :unauthorized
        end

        if password_params[:new_password] != password_params[:confirm_password]
          return render json: {
            status: "error",
            message: "Failed to update password",
            errors: ["Password confirmation doesn't match Password"]
          }, status: :unprocessable_entity
        end

        if password_params[:new_password].length < 6
          return render json: {
            status: "error",
            message: "Failed to update password",
            errors: ["Password is too short (minimum is 6 characters)"]
          }, status: :unprocessable_entity
        end

        if @current_user.update(password: password_params[:new_password])
          render json: {
            status: "success",
            message: "Password updated successfully"
          }, status: :ok
        else
          render json: {
            status: "error",
            message: "Failed to update password",
            errors: @current_user.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      private

      def personal_information_params
        params.require(:personal_information).permit(
          :first_name, 
          :last_name, 
          :email, 
          :phone_number, 
          :bio,
          :avatar_url
        )
      end

      def company_details_params
        params.require(:company_details).permit(
          :company_name,
          :gst_name,
          :gst_number,
          :company_phone,
          :company_address,
          :company_website
        ).transform_keys do |key|
          case key
          when 'company_phone' then 'phone_number'
          when 'company_address' then 'address'
          when 'company_website' then 'company_website'
          else key
          end
        end
      end

      def password_params
        params.permit(:current_password, :new_password, :confirm_password)
      end
    end
  end
end