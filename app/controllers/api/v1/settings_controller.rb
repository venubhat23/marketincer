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
              avatar_url: @current_user.avatar_url,
              timezone: @current_user.timezone
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

      # GET /api/v1/settings/timezones - Get available timezones
      def timezones
        timezones = [
          { value: 'Asia/Kolkata', label: 'India Standard Time (IST)', offset: '+05:30' },
          { value: 'America/New_York', label: 'Eastern Time (ET)', offset: '-05:00' },
          { value: 'America/Los_Angeles', label: 'Pacific Time (PT)', offset: '-08:00' },
          { value: 'Europe/London', label: 'Greenwich Mean Time (GMT)', offset: '+00:00' },
          { value: 'Europe/Berlin', label: 'Central European Time (CET)', offset: '+01:00' },
          { value: 'Asia/Tokyo', label: 'Japan Standard Time (JST)', offset: '+09:00' },
          { value: 'Asia/Shanghai', label: 'China Standard Time (CST)', offset: '+08:00' },
          { value: 'Australia/Sydney', label: 'Australian Eastern Time (AET)', offset: '+10:00' },
          { value: 'Asia/Dubai', label: 'Gulf Standard Time (GST)', offset: '+04:00' },
          { value: 'Asia/Singapore', label: 'Singapore Standard Time (SGT)', offset: '+08:00' },
          { value: 'Europe/Paris', label: 'Central European Time (CET)', offset: '+01:00' },
          { value: 'America/Chicago', label: 'Central Time (CT)', offset: '-06:00' },
          { value: 'America/Denver', label: 'Mountain Time (MT)', offset: '-07:00' },
          { value: 'Pacific/Auckland', label: 'New Zealand Standard Time (NZST)', offset: '+12:00' },
          { value: 'Africa/Cairo', label: 'Eastern European Time (EET)', offset: '+02:00' }
        ]

        render json: {
          status: "success",
          data: timezones
        }, status: :ok
      end

      # PATCH /api/v1/settings/timezone - Update timezone
      def update_timezone
        if @current_user.update(timezone_params)
          render json: {
            status: "success",
            message: "Timezone updated successfully",
            data: {
              timezone: @current_user.timezone
            }
          }, status: :ok
        else
          render json: {
            status: "error",
            message: "Failed to update timezone",
            errors: @current_user.errors.full_messages
          }, status: :unprocessable_entity
        end
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
              avatar_url: @current_user.avatar_url,
              timezone: @current_user.timezone
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

      # DELETE /api/v1/settings/delete_account - Delete user account
      def delete_account
        unless @current_user.authenticate(delete_account_params[:password])
          return render json: {
            status: "error",
            message: "Password is incorrect"
          }, status: :unauthorized
        end

        begin
          # Soft delete by deactivating the account instead of hard delete
          # to preserve data integrity for related records
          if @current_user.update(activated: false, email: "deleted_#{Time.current.to_i}_#{@current_user.email}")
            render json: {
              status: "success",
              message: "Account deleted successfully"
            }, status: :ok
          else
            render json: {
              status: "error",
              message: "Failed to delete account",
              errors: @current_user.errors.full_messages
            }, status: :unprocessable_entity
          end
        rescue => e
          render json: {
            status: "error",
            message: "Failed to delete account",
            errors: [e.message]
          }, status: :internal_server_error
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
          :avatar_url,
          :timezone
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

      def timezone_params
        params.permit(:timezone)
      end

      def delete_account_params
        params.permit(:password)
      end
    end
  end
end