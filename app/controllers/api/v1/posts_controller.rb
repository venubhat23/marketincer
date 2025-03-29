module Api
  module V1
    class PostsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_social_page, only: [:create, :schedule]
      before_action :set_post, only: [:update, :destroy]

      # Create a new post
      def create
        post = @current_user.posts.new(post_params.merge(account_id: params[:social_page_id]))
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

      # Search posts
      def search
        posts = Post.all

        # Apply filters if present
        posts = posts.where(status: params[:postType].strip) if params[:postType].present?
        posts = posts.where(state: params[:state].strip) if params[:state].present?

        if params[:query].present?
          query = "%#{params[:query].strip}%"
          posts = posts.where("note ILIKE :q OR comments ILIKE :q OR brand_name ILIKE :q", q: query)
        end

        if params[:from].present? && params[:to].present?
          from_date = DateTime.parse(params[:from]) rescue nil
          to_date = DateTime.parse(params[:to]) rescue nil
          posts = posts.where(scheduled_at: from_date..to_date) if from_date && to_date
        end

        posts = posts.where(account_id: params[:account_ids]) if params[:account_ids].present?

        # Format response
        formatted_posts = posts.map do |post|
          social_page = post.social_page
          social_account = social_page&.social_account

          post_data = {
            start: post.scheduled_at,
            end: post.scheduled_at,
            brand_name: post.brand_name,
            comments: post.comments,
            hashtags: post.hashtags,
            note: post.note,
            s3_url: post.s3_url,
            status: post.status,
            created_at: post.created_at,
            account_id: post.account_id,
            scheduled_at: post.scheduled_at
          }

          if social_page && social_account
            post_data[:page_data] = {
              id: social_page.id,
              social_account_id: social_page.social_account_id,
              name: social_page.name,
              username: social_page.username,
              page_type: social_page.page_type,
              social_id: social_page.social_id,
              page_id: social_page.page_id,
              picture_url: social_page.picture_url,
              access_token: social_page.access_token,
              connected: social_page.connected,
              page_info: social_page.page_info,
              created_at: social_page.created_at,
              updated_at: social_page.updated_at
            }
            # No need to include social_page and social_account explicitly if page_data is enough
          end

          post_data
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
        post = @current_user.posts.new(post_params.merge(account_id: params[:social_page_id]))
        post.social_page = @social_page
        post.status = "scheduled"

        if post.save
          PostPublisherWorker.perform_at(post.scheduled_at, post.id)
          render json: { status: "success", message: "Post scheduled successfully", post: post_response(post) }
        else
          render json: { status: "error", message: post.errors.full_messages.join(", ") }, status: :unprocessable_entity
        end
      end

      private

      def set_social_page
        @social_page = SocialPage.find_by(social_id: params[:social_page_id])
        render json: { status: "error", message: "Social Page not found" }, status: :not_found unless @social_page
      end

      def set_post
        @post = Post.find_by(id: params[:id])
        render json: { status: "error", message: "Post not found" }, status: :not_found unless @post
      end

      def post_params
        params.require(:post).permit(:s3_url, :hashtags, :note, :comments, :brand_name, :status, :scheduled_at)
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
