module Api
  module V1
    class InstagramInfluencerDiscoveryController < ApplicationController
      # Skip authentication for this public API
      skip_before_action :authenticate_user!, only: [:discover]

      # POST /api/v1/instagram/discover
      # Public endpoint for Instagram influencer discovery
      def discover
        begin
          # Validate required parameters
          unless params[:filters].present?
            return render json: {
              success: false,
              error: "Missing required parameter: filters",
              message: "Please provide filters for influencer discovery"
            }, status: :bad_request
          end

          # Extract and validate filters
          filters = params[:filters].permit!.to_h
          limit = params[:limit]&.to_i || 20
          sort_by = params[:sort_by] || 'followers'

          # Validate limit
          if limit > 100
            return render json: {
              success: false,
              error: "Limit too high",
              message: "Maximum limit is 100 influencers per request"
            }, status: :bad_request
          end

          # Initialize the discovery service
          discovery_service = InstagramInfluencerDiscoveryService.new(
            filters: filters,
            limit: limit,
            sort_by: sort_by
          )

          # Perform the discovery
          result = discovery_service.discover_influencers

          if result[:success]
            render json: {
              success: true,
              message: "Influencers discovered successfully",
              total_results: result[:total_results],
              limit: limit,
              sort_by: sort_by,
              filters_applied: filters,
              results: result[:influencers],
              search_metadata: {
                search_time: result[:search_time],
                ai_provider: result[:ai_provider],
                query_complexity: result[:query_complexity]
              }
            }, status: :ok
          else
            render json: {
              success: false,
              error: result[:error],
              message: result[:message] || "Failed to discover influencers"
            }, status: :unprocessable_entity
          end

        rescue StandardError => e
          Rails.logger.error "Instagram Influencer Discovery Error: #{e.message}"
          Rails.logger.error "Backtrace: #{e.backtrace.join("\n")}"
          
          render json: {
            success: false,
            error: "Internal server error",
            message: "An unexpected error occurred while discovering influencers"
          }, status: :internal_server_error
        end
      end

      private

      def discovery_params
        params.permit(
          :limit,
          :sort_by,
          :username_search,
          filters: [
            :username_search,
            :type,
            :size,
            :gender,
            :location,
            :country,
            :age_range_min,
            :age_range_max,
            categories: [],
            audience_filters: [
              :age_range_min,
              :age_range_max,
              :gender,
              :location,
              :quality_score_min,
              interests: []
            ],
            performance_filters: [
              :avg_views_min,
              :engagement_rate_min,
              :follower_growth_min,
              :comment_rate_min
            ]
          ]
        )
      end
    end
  end
end