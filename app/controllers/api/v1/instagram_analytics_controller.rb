module Api
  module V1
    class InstagramAnalyticsController < ApplicationController
      before_action :authenticate_user!
      before_action :find_social_page, only: [:show, :profile, :media, :analytics]

      # GET /api/v1/instagram_analytics
      # Get analytics for all user's Instagram pages
      def index
        begin
          # Optimize database query with eager loading and specific fields
          social_pages = SocialPage.includes(:social_account)
                                   .where(social_accounts: { user_id: @current_user.id })
                                   .where(page_type: 'instagram')
                                   .where.not(access_token: [nil, ''])
                                   .select('social_pages.id, social_pages.page_id, social_pages.name,
                                           social_pages.username, social_pages.social_id, social_pages.access_token')

          if social_pages.empty?
            return render json: {
              success: false,
              message: "No Instagram pages found",
              data: []
            }, status: 404
          end

          # Process pages in parallel threads for better performance
          analytics_data = []
          threads = []

          social_pages.each do |page|
            threads << Thread.new do
              begin
                service = InstagramAnalyticsService.new(page.access_token)
                page_analytics = service.get_comprehensive_analytics(page.social_id)

                Thread.current[:result] = {
                  page_id: page.page_id,
                  page_name: page.name,
                  username: page.username,
                  social_id: page.social_id,
                  **page_analytics
                }
              rescue => e
                Rails.logger.error "Error processing page #{page.page_id}: #{e.message}"
                Thread.current[:result] = {
                  page_id: page.page_id,
                  page_name: page.name,
                  username: page.username,
                  social_id: page.social_id,
                  error: "Failed to fetch analytics: #{e.message}"
                }
              end
            end
          end

          # Wait for all threads to complete with timeout
          threads.each { |t| t.join(30) } # 30 second timeout per thread
          analytics_data = threads.map { |t| t[:result] }.compact

          render json: {
            success: true,
            message: "Instagram analytics retrieved successfully",
            total_pages: analytics_data.length,
            data: analytics_data
          }

        rescue => e
          Rails.logger.error "Instagram Analytics Index Error: #{e.message}"
          render json: {
            success: false,
            message: "Failed to retrieve Instagram analytics",
            error: e.message,
            data: []
          }, status: 500
        end
      end

      # GET /api/v1/instagram_analytics/:page_id
      # Get comprehensive analytics for a specific Instagram page
      def show
        begin
          service = InstagramAnalyticsService.new(@social_page.access_token)
          analytics = service.get_comprehensive_analytics(@social_page.social_id)

          render json: {
            success: true,
            message: "Instagram analytics retrieved successfully",
            page_info: {
              page_id: @social_page.page_id,
              page_name: @social_page.name,
              username: @social_page.username,
              social_id: @social_page.social_id
            },
            data: analytics
          }

        rescue => e
          Rails.logger.error "Instagram Analytics Show Error: #{e.message}"
          render json: {
            success: false,
            message: "Failed to retrieve Instagram analytics",
            error: e.message,
            data: {}
          }, status: 500
        end
      end

      # GET /api/v1/instagram_analytics/:page_id/profile
      # Get profile data only
      def profile
        begin
          service = InstagramAnalyticsService.new(@social_page.access_token)
          profile_data = service.get_user_profile(@social_page.social_id)

          if profile_data.blank?
            return render json: {
              success: false,
              message: "No profile data found",
              data: {}
            }, status: 404
          end

          render json: {
            success: true,
            message: "Instagram profile retrieved successfully",
            data: profile_data
          }

        rescue => e
          Rails.logger.error "Instagram Profile Error: #{e.message}"
          render json: {
            success: false,
            message: "Failed to retrieve Instagram profile",
            error: e.message,
            data: {}
          }, status: 500
        end
      end

      # GET /api/v1/instagram_analytics/:page_id/media
      # Get media data only
      def media
        begin
          limit = params[:limit]&.to_i || 25
          service = InstagramAnalyticsService.new(@social_page.access_token)
          media_data = service.get_user_media(@social_page.social_id, limit)

          render json: {
            success: true,
            message: "Instagram media retrieved successfully",
            total_media: media_data['data']&.length || 0,
            data: media_data
          }

        rescue => e
          Rails.logger.error "Instagram Media Error: #{e.message}"
          render json: {
            success: false,
            message: "Failed to retrieve Instagram media",
            error: e.message,
            data: { 'data' => [] }
          }, status: 500
        end
      end

      # GET /api/v1/instagram_analytics/:page_id/analytics
      # Get analytics data only
      def analytics
        begin
          service = InstagramAnalyticsService.new(@social_page.access_token)
          analytics_data = service.analyze_user_content(@social_page.social_id)

          render json: {
            success: true,
            message: "Instagram analytics retrieved successfully",
            data: analytics_data
          }

        rescue => e
          Rails.logger.error "Instagram Analytics Error: #{e.message}"
          render json: {
            success: false,
            message: "Failed to retrieve Instagram analytics",
            error: e.message,
            data: {}
          }, status: 500
        end
      end

      # GET /api/v1/instagram_analytics/:page_id/media/:media_id
      # Get specific media details
      def media_details
        begin
          media_id = params[:media_id]
          service = InstagramAnalyticsService.new(@social_page.access_token)
          media_data = service.get_media_details(media_id)

          if media_data.blank?
            return render json: {
              success: false,
              message: "Media not found",
              data: {}
            }, status: 404
          end

          render json: {
            success: true,
            message: "Media details retrieved successfully",
            data: media_data
          }

        rescue => e
          Rails.logger.error "Instagram Media Details Error: #{e.message}"
          render json: {
            success: false,
            message: "Failed to retrieve media details",
            error: e.message,
            data: {}
          }, status: 500
        end
      end

      private

      def find_social_page
        @social_page = SocialPage.joins(:social_account)
                                 .where(social_accounts: { user_id: @current_user.id })
                                 .where(page_type: 'instagram')
                                 .find_by(page_id: params[:page_id])

        unless @social_page
          render json: {
            success: false,
            message: "Instagram page not found",
            data: {}
          }, status: 404
          return
        end

        if @social_page.access_token.blank?
          render json: {
            success: false,
            message: "No access token found for this Instagram page",
            data: {}
          }, status: 400
          return
        end
      end
    end
  end
end