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

      private

      def page_params
        params.require(:page).permit(
          :name, :username, :page_type, :social_id, :page_id,
          :picture_url, :access_token, user: {}
        )
      end
    end
  end
end
