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
            },
            timezone: @current_user.timezone
          }
        }, status: :ok
      end

      # GET /api/v1/settings/timezones - Get list of available timezones
      def timezones
        timezone_list = [
          { name: "Asia/Kolkata", display_name: "Asia/Kolkata (GMT+05:30)", offset: "+05:30" },
          { name: "America/New_York", display_name: "America/New_York (GMT-05:00)", offset: "-05:00" },
          { name: "America/Los_Angeles", display_name: "America/Los_Angeles (GMT-08:00)", offset: "-08:00" },
          { name: "Europe/London", display_name: "Europe/London (GMT+00:00)", offset: "+00:00" },
          { name: "Europe/Berlin", display_name: "Europe/Berlin (GMT+01:00)", offset: "+01:00" },
          { name: "Asia/Tokyo", display_name: "Asia/Tokyo (GMT+09:00)", offset: "+09:00" },
          { name: "Asia/Shanghai", display_name: "Asia/Shanghai (GMT+08:00)", offset: "+08:00" },
          { name: "Australia/Sydney", display_name: "Australia/Sydney (GMT+10:00)", offset: "+10:00" },
          { name: "Asia/Dubai", display_name: "Asia/Dubai (GMT+04:00)", offset: "+04:00" },
          { name: "Asia/Singapore", display_name: "Asia/Singapore (GMT+08:00)", offset: "+08:00" },
          { name: "Europe/Paris", display_name: "Europe/Paris (GMT+01:00)", offset: "+01:00" },
          { name: "America/Chicago", display_name: "America/Chicago (GMT-06:00)", offset: "-06:00" },
          { name: "America/Denver", display_name: "America/Denver (GMT-07:00)", offset: "-07:00" },
          { name: "Pacific/Auckland", display_name: "Pacific/Auckland (GMT+12:00)", offset: "+12:00" },
          { name: "Africa/Cairo", display_name: "Africa/Cairo (GMT+02:00)", offset: "+02:00" }
        ]

        render json: {
          status: "success",
          data: {
            timezones: timezone_list,
            current_timezone: @current_user.timezone
          }
        }, status: :ok
      end

      # PATCH /api/v1/settings/timezone - Update user timezone
      def update_timezone
        if @current_user.update(timezone: timezone_params[:timezone])
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

      # DELETE /api/v1/settings/delete_account - Delete user account
      def delete_account
        unless @current_user.authenticate(delete_account_params[:password])
          return render json: {
            status: "error",
            message: "Password is incorrect. Account deletion cancelled."
          }, status: :unauthorized
        end

        begin
          # Delete associated records first (handled by dependent: :destroy in User model)
          # This will cascade delete: marketplace_posts, bids, short_urls, etc.
          
          user_email = @current_user.email
          @current_user.destroy!

          render json: {
            status: "success",
            message: "Account deleted successfully. We're sorry to see you go!",
            data: {
              deleted_user_email: user_email,
              deleted_at: Time.current.iso8601
            }
          }, status: :ok

        rescue => e
          render json: {
            status: "error",
            message: "Failed to delete account. Please try again or contact support.",
            error: e.message
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

      def timezone_params
        params.permit(:timezone)
      end

      def delete_account_params
        params.permit(:password)
      end
    end
  end
end