module Api
  module V1
    class PostsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_social_page, only: [:create, :schedule]
      before_action :set_post, only: [:update, :destroy]  # Ensure @post is available

      # Create a new post
      def create
        post = @current_user.posts.new(post_params)
        post.social_page = @social_page

        if post.save
          if post.status == "scheduled"
            render json: { status: "success", message: "Post scheduled successfully", post: post_response(post) }
          elsif post.status != "draft"
            begin
              PostPublisherService.new(post).publish
              render json: { status: "success", publish_log: post.publish_log, post: post_response(post) }
            rescue StandardError => e
              render json: { status: "error", message: post.publish_log, post: { id: post.id, status: post.status, error: e.message } }, status: :unprocessable_entity
            end
          else
            render json: { status: "success", post: post_response(post) }
          end
        else
          render json: { status: "error", message: post.errors.full_messages.join(", ") }, status: :unprocessable_entity
        end
      end

      def search
        posts = Post.all

        # Filter by postType (status)
        posts = posts.where(status: params[:postType]) if params[:postType].present?

        # Filter by state (draft, scheduled, failed)
        posts = posts.where(state: params[:state]) if params[:state].present?

        # Search query (filter by note, comments, brand_name)
        if params[:query].present?
          posts = posts.where("note ILIKE ? OR comments ILIKE ? OR brand_name ILIKE ?", 
                              "%#{params[:query]}%", "%#{params[:query]}%", "%#{params[:query]}%")
        end

        # Filter by date range
        if params[:from].present? && params[:to].present?
          posts = posts.where(created_at: DateTime.parse(params[:from])..DateTime.parse(params[:to]))
        end

        # Filter by account_ids
        posts = posts.where(account_id: params[:account_ids]) if params[:account_ids].present?

        # Select only the required fields
        formatted_posts = posts.select(:id, :s3_url, :hashtags, :note, :comments, :brand_name, :status, :scheduled_at, :created_at).map do |post|
          {
            id: post.id,
            s3_url: post.s3_url,
            hashtags: post.hashtags,
            note: post.note,
            comments: post.comments,
            brand_name: post.brand_name,
            status: post.status,
            scheduled_at: post.scheduled_at,
            created_at: post.created_at
          }
        end

        render json: { posts: formatted_posts, total: posts.count }
      end

      # Update an existing post
      def update
        if @post.update(post_params)
          render json: { status: "success", post: post_response(@post) }, status: :ok
        else
          render json: { status: "error", message: @post.errors.full_messages.join(", ") }, status: :unprocessable_entity
        end
      end

      # Delete a post
      def destroy
        if @post.destroy
          render json: { status: "success", message: "Post deleted successfully" }, status: :ok
        else
          render json: { status: "error", message: "Failed to delete post" }, status: :unprocessable_entity
        end
      end

      # Schedule a post
      def schedule
        post = @current_user.posts.new(post_params)
        post.social_page = @social_page
        post.status = "scheduled"

        if post.save
          render json: { status: "success", message: "Post scheduled successfully", post: post_response(post) }
        else
          render json: { status: "error", message: post.errors.full_messages.join(", ") }, status: :unprocessable_entity
        end
      end

      private

      def set_social_page
        @social_page = SocialPage.find_by(social_id: params[:social_page_id])
      end

      def set_post
        @post = Post.find_by(id: params[:id])
        render json: { status: "error", message: "Post not found" }, status: :not_found unless @post
      end

      def post_params
        params.require(:post).permit(:s3_url, :hashtags, :note, :comments, :brand_name, :status, :scheduled_at, :account_id)
      end

      def post_response(post)
        {
          id: post.id,
          status: post.status,
          scheduled_at: post.scheduled_at,
          created_at: post.created_at,
          brand_name: post.brand_name
        }
      end
    end
  end
end
