module Api
  module V1
    class MarketplacePostsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_marketplace_post, only: [:show, :update, :destroy]
      before_action :check_brand_access, only: [:create, :update, :destroy, :my_posts]

      # GET /api/v1/marketplace_posts
      # For influencers - get published marketplace posts feed
      def index
        # Only influencers can access the marketplace feed
        @marketplace_posts = MarketplacePost.published
                                          .includes(:user, :bids)
                                          .recent

        # Apply filters if provided
        @marketplace_posts = @marketplace_posts.by_category(params[:category]) if params[:category].present?
        @marketplace_posts = @marketplace_posts.by_target_audience(params[:target_audience]) if params[:target_audience].present?

        # Pagination
        page = params[:page]&.to_i || 1
        per_page = params[:per_page]&.to_i || 10
        per_page = [per_page, 50].min # Max 50 per page

        @marketplace_posts = @marketplace_posts.offset((page - 1) * per_page).limit(per_page)

        render json: {
          status: 'success',
          data: @marketplace_posts.map { |post| marketplace_post_card_response(post) },
          pagination: {
            current_page: page,
            per_page: per_page,
            total_count: MarketplacePost.published.count
          }
        }
      end

      # GET /api/v1/marketplace_posts/my_posts
      # For brands/admin - get their own marketplace posts
      def my_posts
        @marketplace_posts = @current_user.marketplace_posts
                                        .includes(:bids)
                                        .recent

        render json: {
          status: 'success',
          data: @marketplace_posts.map { |post| brand_marketplace_post_response(post) }
        }
      end

      # GET /api/v1/marketplace_posts/:id
      # Show single marketplace post (with view increment for influencers)
      def show
        # Increment view count if accessed by influencer
        if @current_user.role == 'influencer'
          @marketplace_post.increment_views!
        end

        if @current_user.role.in?(['admin', 'brand'])
          render json: {
            status: 'success',
            data: brand_marketplace_post_response(@marketplace_post)
          }
        else
          render json: {
            status: 'success',
            data: marketplace_post_detail_response(@marketplace_post)
          }
        end
      end

      # POST /api/v1/marketplace_posts
      # Create new marketplace post (brands/admin only)
      def create
        @marketplace_post = @current_user.marketplace_posts.new(marketplace_post_params)

        if @marketplace_post.save
          render json: {
            status: 'success',
            message: 'Marketplace post created successfully',
            data: brand_marketplace_post_response(@marketplace_post)
          }, status: :created
        else
          render json: {
            status: 'error',
            message: 'Failed to create marketplace post',
            errors: @marketplace_post.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # PUT /api/v1/marketplace_posts/:id
      # Update marketplace post (brands/admin only)
      def update
        if @marketplace_post.update(marketplace_post_params)
          render json: {
            status: 'success',
            message: 'Marketplace post updated successfully',
            data: brand_marketplace_post_response(@marketplace_post)
          }
        else
          render json: {
            status: 'error',
            message: 'Failed to update marketplace post',
            errors: @marketplace_post.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/marketplace_posts/:id
      # Delete marketplace post (brands/admin only)
      def destroy
        @marketplace_post.destroy
        render json: {
          status: 'success',
          message: 'Marketplace post deleted successfully'
        }
      end

      # GET /api/v1/marketplace_posts/search
      # Search marketplace posts (influencers only)
      def search
        unless @current_user.role == 'influencer'
          return render json: { 
            status: 'error', 
            message: 'Access denied. Influencer role required.' 
          }, status: :forbidden
        end

        query = params[:q]
        filters = {
          category: params[:category],
          target_audience: params[:target_audience],
          budget_min: params[:budget_min],
          budget_max: params[:budget_max],
          deadline_from: params[:deadline_from],
          deadline_to: params[:deadline_to],
          location: params[:location],
          platform: params[:platform]
        }

        @marketplace_posts = MarketplaceService.search_posts(query, filters)

        # Pagination
        page = params[:page]&.to_i || 1
        per_page = params[:per_page]&.to_i || 10
        per_page = [per_page, 50].min

        @marketplace_posts = @marketplace_posts.offset((page - 1) * per_page).limit(per_page)

        render json: {
          status: 'success',
          data: @marketplace_posts.map { |post| marketplace_post_card_response(post) },
          pagination: {
            current_page: page,
            per_page: per_page,
            total_count: MarketplaceService.search_posts(query, filters).count
          }
        }
      end

      # GET /api/v1/marketplace_posts/statistics
      # Get marketplace statistics
      def statistics
        if @current_user.role.in?(['admin', 'brand'])
          stats = MarketplaceService.brand_statistics(@current_user)
        elsif @current_user.role == 'influencer'
          stats = MarketplaceService.influencer_statistics(@current_user)
        else
          stats = {}
        end

        render json: {
          status: 'success',
          data: stats
        }
      end

      # GET /api/v1/marketplace_posts/insights
      # Get marketplace insights (admin only)
      def insights
        unless @current_user.role == 'admin'
          return render json: { 
            status: 'error', 
            message: 'Access denied. Admin role required.' 
          }, status: :forbidden
        end

        insights = MarketplaceService.marketplace_insights

        render json: {
          status: 'success',
          data: insights
        }
      end

      # GET /api/v1/marketplace_posts/recommended
      # Get recommended posts for influencer
      def recommended
        unless @current_user.role == 'influencer'
          return render json: { 
            status: 'error', 
            message: 'Access denied. Influencer role required.' 
          }, status: :forbidden
        end

        limit = params[:limit]&.to_i || 10
        @recommended_posts = MarketplaceService.recommended_posts(@current_user, limit)

        render json: {
          status: 'success',
          data: @recommended_posts.map { |post| marketplace_post_card_response(post) }
        }
      end

      private

      def set_marketplace_post
        @marketplace_post = MarketplacePost.find(params[:id])
        
        # Ensure brands can only access their own posts
        #if @current_user.role.in?(['brand']) && @marketplace_post.user_id != @current_user.id
          #render json: { status: 'error', message: 'Access denied' }, status: :forbidden
          #return
        #end
      rescue ActiveRecord::RecordNotFound
        render json: { status: 'error', message: 'Marketplace post not found' }, status: :not_found
      end

      def marketplace_post_params
        params.require(:marketplace_post).permit(
          :title, :description, :category, :target_audience, :budget,
          :location, :platform, :languages, :deadline, :tags, :status,
          :brand_name, :media_url, :media_type
        )
      end

      def check_brand_access
        unless @current_user.role.in?(['Admin', 'Brand'])
          render json: { status: 'error', message: 'Access denied. Brand or admin role required.' }, status: :forbidden
        end
      end

      def check_influencer_access
        #unless @current_user.role == 'influencer'
          #render json: { status: 'error', message: 'Access denied. Influencer role required.' }, status: :forbidden
        #end
      end

      # Response format for influencer marketplace feed (card view)
      def marketplace_post_card_response(post)
        {
          id: post.id,
          title: post.title,
          description: post.description.truncate(150),
          brand_name: post.brand_name,
          budget: post.budget,
          deadline: post.deadline,
          location: post.location,
          platform: post.platform,
          category: post.category,
          target_audience: post.target_audience,
          tags: post.tags_array,
          media_url: post.media_url,
          media_type: post.media_type,
          views_count: post.views_count,
          bids_count: post.bids_count,
          created_at: post.created_at,
          user_has_bid: post.bids.exists?(user: @current_user)
        }
      end

      # Response format for influencer post detail view
      def marketplace_post_detail_response(post)
        {
          id: post.id,
          title: post.title,
          description: post.description,
          brand_name: post.brand_name,
          budget: post.budget,
          deadline: post.deadline,
          location: post.location,
          platform: post.platform,
          languages: post.languages,
          category: post.category,
          target_audience: post.target_audience,
          tags: post.tags_array,
          media_url: post.media_url,
          media_type: post.media_type,
          views_count: post.views_count,
          bids_count: post.bids_count,
          created_at: post.created_at,
          user_has_bid: post.bids.exists?(user: @current_user),
          user_bid: post.bids.find_by(user: @current_user)&.then { |bid|
            {
              id: bid.id,
              amount: bid.amount,
              status: bid.status,
              created_at: bid.created_at
            }
          }
        }
      end

      # Response format for brand marketplace post management
      def brand_marketplace_post_response(post)
        {
          id: post.id,
          title: post.title,
          description: post.description,
          brand_name: post.brand_name,
          budget: post.budget,
          deadline: post.deadline,
          location: post.location,
          platform: post.platform,
          languages: post.languages,
          category: post.category,
          target_audience: post.target_audience,
          tags: post.tags_array,
          media_url: post.media_url,
          media_type: post.media_type,
          status: post.status,
          views_count: post.views_count,
          bids_count: post.bids_count,
          pending_bids_count: post.pending_bids_count,
          accepted_bids_count: post.accepted_bids_count,
          rejected_bids_count: post.rejected_bids_count,
          created_at: post.created_at,
          updated_at: post.updated_at
        }
      end
    end
  end
end