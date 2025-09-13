module Api
  module V1
    class PostsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_post, only: [:update, :destroy]

      # Create posts for multiple social_page_ids
      def create
        created_posts = []
        errors = []
        flattened_uniq_array = params[:social_page_ids].flatten.uniq
        flattened_uniq_array.each do |social_page_id|
          social_page = SocialPage.find_by(social_id: social_page_id)

          unless social_page
            errors << { social_page_id: social_page_id, error: "Social Page not found" }
            next
          end

          post = @current_user.posts.new(post_params.merge(account_id: social_page.social_id))
          post.social_page = social_page

          begin
            # First, save the post in a transaction
            ActiveRecord::Base.transaction do
              unless post.save
                raise ActiveRecord::RecordInvalid.new(post)
              end
            end

            # Then handle publishing outside the transaction
            if post.status == "scheduled"
              created_posts << { message: "Post scheduled successfully", post: post_response(post) }
            elsif post.status != "draft"
              begin
                PostPublisherService.new(post).publish
                post.reload # Reload to get updated publish_log
                created_posts << { publish_log: post.publish_log, post: post_response(post) }
              rescue StandardError => e
                # Post was saved but publishing failed - keep the post with failed status
                post.reload # Reload to get the failed status and error message
                errors << { social_page_id: social_page_id, error: e.message, post: post_response(post) }
              end
            else
              created_posts << { post: post_response(post) }
            end
          rescue ActiveRecord::RecordInvalid => e
            errors << { social_page_id: social_page_id, error: e.record.errors.full_messages.join(", ") }
          rescue StandardError => e
            # This catches any other unexpected errors
            post.destroy if post.persisted?
            errors << { social_page_id: social_page_id, error: e.message }
          end
        end

        response_data = {
          status: errors.any? && created_posts.any? ? "partial_success" :
                  errors.any? && created_posts.empty? ? "error" : "success",
          posts: created_posts,
          errors: errors
        }

        response_data[:message] = "All posts failed to create" if errors.any? && created_posts.empty?

        status_code = if errors.any? && created_posts.any?
                       :multi_status
                     elsif errors.any? && created_posts.empty?
                       :unprocessable_entity
                     else
                       :ok
                     end

        render json: response_data, status: status_code
      end

      # Schedule posts for multiple social_page_ids
      def schedule
        created_posts = []
        errors = []

        params[:social_page_ids].each do |social_page_id|
          social_page = SocialPage.find_by(social_id: social_page_id)

          unless social_page
            errors << { social_page_id: social_page_id, error: "Social Page not found" }
            next
          end

          if params[:existing_post_id].present?
            old_post = Post.find_by(id: params[:existing_post_id])
            old_post.destroy if old_post
          end

          post = @current_user.posts.new(post_params.merge(account_id: social_page_id))
          post.social_page = social_page
          post.status = "scheduled"

          if post.save
            PostPublisherWorker.perform_at(post.scheduled_at, post.id)
            created_posts << { message: "Post scheduled successfully", post: post_response(post) }
          else
            errors << { social_page_id: social_page_id, error: post.errors.full_messages.join(", ") }
          end
        end

        if errors.any?
          render json: { status: "partial_success", posts: created_posts, errors: errors }, status: :multi_status
        else
          render json: { status: "success", posts: created_posts }
        end
      end

      def update
        if @post.update(post_params)
          render json: { status: "success", post: post_response(@post) }, status: :ok
        else
          render json: { status: "error", message: @post.errors.full_messages.join(", ") }, status: :unprocessable_entity
        end
      end

      def destroy
        if @post.destroy
          render json: { status: "success", message: "Post deleted successfully" }, status: :ok
        else
          render json: { status: "error", message: "Failed to delete post" }, status: :unprocessable_entity
        end
      end

      def search
        posts = Post.all
        posts = posts.where(status: params[:postType].strip) if params[:postType].present?
        posts = posts.where(state: params[:state].strip) if params[:state].present?

        if params[:query].present?
          query = "%#{params[:query].strip}%"
          posts = posts.where("note ILIKE :q OR comments ILIKE :q OR brand_name ILIKE :q", q: query)
        end

        if params[:from].present? && params[:to].present?
          from_date = DateTime.parse(params[:from]) rescue nil
          to_date = DateTime.parse(params[:to]) rescue nil
          to_date = to_date.end_of_day if to_date
          posts = posts.where(scheduled_at: from_date..to_date) if from_date && to_date
        end

        posts = posts.where(account_id: params[:account_ids]) if params[:account_ids].present?

        formatted_posts = posts.map do |post|
          social_page = post.social_page
          social_account = social_page&.social_account

          post_data = {
            post_id: post.id,
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
          end

          post_data
        end

        render json: { posts: formatted_posts, total: posts.count }
      end

      private

      def set_post
        @post = Post.find_by(id: params[:id])
        render json: { status: "error", message: "Post not found" }, status: :not_found unless @post
      end

      def post_params
        params.require(:post).permit(:s3_url, :hashtags, :note, :comments, :brand_name, :status, :scheduled_at)
      end

      def post_response(post)
        response = {
          id: post.id,
          status: post.status,
          scheduled_at: post.scheduled_at,
          created_at: post.created_at,
          brand_name: post.brand_name
        }

        # Include error message if post failed
        if post.status == 'failed' && post.publish_log.present?
          response[:error_message] = post.publish_log
        end

        response
      end
    end
  end
end
