# app/controllers/api/v1/posts_controller.rb
module Api
  module V1
    class PostsController < ApplicationController
      before_action :authenticate_request
      before_action :set_social_page, only: [:create]

      def create
        post = current_user.posts.new(post_params)
        post.social_page = @social_page

        if post.save
          PostPublisherService.new(post).publish
          render json: { status: 'success', message: 'Post published successfully' }
        else
          render json: { errors: post.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def set_social_page
        @social_page = current_user.social_accounts
                                 .joins(:social_pages)
                                 .find_by!(social_pages: { id: params[:social_page_id] })
      end

      def post_params
        params.require(:post).permit(:s3_url, :hashtags, :note, :comments, :brand_name)
      end
    end
  end
end

