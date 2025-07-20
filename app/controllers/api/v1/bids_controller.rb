module Api
  module V1
    class BidsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_marketplace_post, only: [:create, :index]
      before_action :set_bid, only: [:show, :update, :destroy, :accept, :reject]
      before_action :check_influencer_access, only: [:create]
      before_action :check_brand_access, only: [:index, :accept, :reject]

      # GET /api/v1/marketplace_posts/:marketplace_post_id/bids
      # Get all bids for a marketplace post (brands/admin only)
      def index
        @bids = @marketplace_post.bids
                               .includes(:user)
                               .recent

        render json: {
          status: 'success',
          data: {
            marketplace_post: {
              id: @marketplace_post.id,
              title: @marketplace_post.title,
              budget: @marketplace_post.budget
            },
            bids: @bids.map { |bid| bid_response(bid) },
            summary: {
              total_bids: @bids.count,
              pending_bids: @bids.pending.count,
              accepted_bids: @bids.accepted.count,
              rejected_bids: @bids.rejected.count
            }
          }
        }
      end

      # POST /api/v1/marketplace_posts/:marketplace_post_id/bids
      # Create a new bid (influencers only)
      def create
        # Check if user already has a bid for this post
        existing_bid = @marketplace_post.bids.find_by(user: @current_user)
        if existing_bid
          return render json: {
            status: 'error',
            message: 'You have already placed a bid for this post',
            data: bid_response(existing_bid)
          }, status: :unprocessable_entity
        end

        @bid = @marketplace_post.bids.new(bid_params)
        @bid.user = @current_user

        if @bid.save
          render json: {
            status: 'success',
            message: 'Bid placed successfully',
            data: bid_response(@bid)
          }, status: :created
        else
          render json: {
            status: 'error',
            message: 'Failed to place bid',
            errors: @bid.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # GET /api/v1/bids/:id
      # Show single bid
      def show
        render json: {
          status: 'success',
          data: bid_detail_response(@bid)
        }
      end

      # PUT /api/v1/bids/:id
      # Update bid (influencer can update their own pending bids)
      def update
        unless @bid.pending?
          return render json: {
            status: 'error',
            message: 'Cannot update bid that has been accepted or rejected'
          }, status: :unprocessable_entity
        end

        if @bid.update(bid_params)
          render json: {
            status: 'success',
            message: 'Bid updated successfully',
            data: bid_response(@bid)
          }
        else
          render json: {
            status: 'error',
            message: 'Failed to update bid',
            errors: @bid.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/bids/:id
      # Delete bid (influencer can delete their own pending bids)
      def destroy
        unless @bid.pending?
          return render json: {
            status: 'error',
            message: 'Cannot delete bid that has been accepted or rejected'
          }, status: :unprocessable_entity
        end

        @bid.destroy
        render json: {
          status: 'success',
          message: 'Bid deleted successfully'
        }
      end

      # POST /api/v1/bids/:id/accept
      # Accept a bid (brands/admin only)
      def accept
        if @bid.accept!
          render json: {
            status: 'success',
            message: 'Bid accepted successfully',
            data: bid_response(@bid)
          }
        else
          render json: {
            status: 'error',
            message: 'Failed to accept bid',
            errors: @bid.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/bids/:id/reject
      # Reject a bid (brands/admin only)
      def reject
        if @bid.reject!
          render json: {
            status: 'success',
            message: 'Bid rejected successfully',
            data: bid_response(@bid)
          }
        else
          render json: {
            status: 'error',
            message: 'Failed to reject bid',
            errors: @bid.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # GET /api/v1/bids/my_bids
      # Get current user's bids (influencers only)
      def my_bids
        @bids = @current_user.bids
                           .includes(:marketplace_post)
                           .recent

        render json: {
          status: 'success',
          data: @bids.map { |bid| my_bid_response(bid) }
        }
      end

      private

      def set_marketplace_post
        @marketplace_post = MarketplacePost.find(params[:marketplace_post_id])
      rescue ActiveRecord::RecordNotFound
        render json: { status: 'error', message: 'Marketplace post not found' }, status: :not_found
      end

      def set_bid
        @bid = Bid.find(params[:id])
        
        # Access control
        if @current_user.role == 'influencer' && @bid.user_id != @current_user.id
          render json: { status: 'error', message: 'Access denied' }, status: :forbidden
          return
        elsif @current_user.role == 'brand' && @bid.marketplace_post.user_id != @current_user.id
          render json: { status: 'error', message: 'Access denied' }, status: :forbidden
          return
        end
      rescue ActiveRecord::RecordNotFound
        render json: { status: 'error', message: 'Bid not found' }, status: :not_found
      end

      def bid_params
        params.require(:bid).permit(:amount, :message)
      end

      def check_brand_access
      end

      def check_influencer_access
      end

      # Standard bid response
      def bid_response(bid)
        {
          id: bid.id,
          amount: bid.amount,
          status: bid.status,
          message: bid.message,
          influencer_name: bid.influencer_name,
          influencer_email: bid.user.email,
          created_at: bid.created_at,
          updated_at: bid.updated_at
        }
      end

      # Detailed bid response
      def bid_detail_response(bid)
        {
          id: bid.id,
          amount: bid.amount,
          status: bid.status,
          message: bid.message,
          influencer: {
            id: bid.user.id,
            name: bid.influencer_name,
            email: bid.user.email,
            first_name: bid.user.first_name,
            last_name: bid.user.last_name
          },
          marketplace_post: {
            id: bid.marketplace_post.id,
            title: bid.marketplace_post.title,
            budget: bid.marketplace_post.budget,
            brand_name: bid.marketplace_post.brand_name
          },
          created_at: bid.created_at,
          updated_at: bid.updated_at
        }
      end

      # Response for influencer's own bids
      def my_bid_response(bid)
        {
          id: bid.id,
          amount: bid.amount,
          status: bid.status,
          message: bid.message,
          marketplace_post: {
            id: bid.marketplace_post.id,
            title: bid.marketplace_post.title,
            brand_name: bid.marketplace_post.brand_name,
            budget: bid.marketplace_post.budget,
            deadline: bid.marketplace_post.deadline,
            status: bid.marketplace_post.status
          },
          created_at: bid.created_at,
          updated_at: bid.updated_at
        }
      end
    end
  end
end