# app/controllers/api/v1/social_pages_controller.rb
module Api
  module V1
    class SocialPagesController < ApplicationController
      before_action :authenticate_user!

      def connect
        social_page = SocialPageConnectorService.new(
          @current_user,
          page_params
        ).connect
        
        render json: { status: 'success', message: 'Page connected successfully' }
      end

      def connected_pages
        pages = @current_user.social_accounts.joins(:social_pages)
                          .where(social_pages: { connected: true })
                          .select('social_pages.*')
        
        render json: {
          data: { accounts: pages },
          status: "complete"
        }
      end

      def dis_connect
        ActiveRecord::Base.transaction do
          social_page = SocialPage.find_by(id: params[:page][:id])
          social_account = SocialAccount.find_by(id: params[:page][:social_account_id])

          if social_page.nil? || social_account.nil?
            return render json: { status: 'error', message: 'Invalid social page or social account ID' }, status: :unprocessable_entity
          end

          social_page.posts.delete_all
          social_page.destroy

          render json: { status: 'success', message: 'Successfully disconnected' }
        end
      rescue ActiveRecord::RecordInvalid => e
        render json: { status: 'error', message: e.message }, status: :unprocessable_entity
      rescue StandardError => e
        render json: { status: 'error', message: 'Something went wrong, please retry' }, status: :internal_server_error
      end
      private

      def page_params
        params.require(:page).permit(
          :name, :username, :page_type, :social_id, :page_id, :is_page,
          :picture_url, :access_token, user: {}
        )
      end
    end
  end
end
