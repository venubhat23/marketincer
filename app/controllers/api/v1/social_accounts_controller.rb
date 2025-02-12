# app/controllers/api/v1/social_accounts_controller.rb
module Api
  module V1
    class SocialAccountsController < ApplicationController

      def get_pages
        fb_auth_token = params[:auth_token]
        pages = FacebookPagesService.new(fb_auth_token).fetch_pages
        
        render json: {
          data: { accounts: pages },
          status: "complete",
          long_poll: true
        }
      end
    end
  end
end
