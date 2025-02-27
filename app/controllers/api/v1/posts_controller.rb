#class Api::V1::PostsController < ApplicationController
 # before_action :authenticate_user! # Ensure the user is authenticated

  # POST /api/v1/posts
  #def create
    # Create a new post associated with the current_user
   # post = @current_user.posts.new(post_params)

    #if post.save
     # render json: { message: 'Post created successfully', post: post,status: post.status }, status: :created
    #else
     # render json: { errors: post.errors.full_messages }, status: :unprocessable_entity
    #end
  #end

  private

  # Permit the necessary post parameters
  #def post_params
   # params.require(:post).permit(:s3_url, :status, :hashtags, :note, :comments, :brand_name)
  #end
#end


# app/controllers/api/v1/posts_controller.rb
module Api
  module V1
    class PostsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_social_page, only: [:create]

      def create
        post = @current_user.posts.new(post_params)
        post.social_page = @social_page

        if post.save
          begin
            if post.status != "draft"
              PostPublisherService.new(post).publish
              
              render json: {
                status: 'success',
                publish_log: post.publish_log,
                post: {
                  id: post.id,
                  status: post.status,
                  created_at: post.created_at,
                  brand_name: post.brand_name
                }
              }
            else              
              render json: {
                status: 'success',
                post: {
                  id: post.id,
                  status: post.status,
                  created_at: post.created_at,
                  brand_name: post.brand_name
                }
              }
            end
          rescue StandardError => e
            render json: {
              status: 'error',
              message: post.publish_log,
              post: {
                id: post.id,
                status: post.status,
                error: e.message
              }
            }, status: :unprocessable_entity
          end
        else
          render json: { 
            status: 'error',
            message: post.errors.full_messages.join(', ')
          }, status: :unprocessable_entity
        end
      end

      private

      def set_social_page
        @social_page = SocialPage.where(social_id: params[:social_page_id]).last
      end

      def post_params
        params.require(:post).permit(:s3_url, :hashtags, :note, :comments, :brand_name, :status)
      end
    end
  end
end

