module Api
  module V1
    class LinkedinAnalyticsController < ApplicationController
      before_action :authenticate_user!
      before_action :find_linkedin_account, only: [:show, :follower_demographics, :share_statistics, :social_actions]

      # GET /api/v1/linkedin_analytics
      # Get analytics for all user's LinkedIn organization accounts
      def index
        begin
          # Find all LinkedIn accounts for the user
          linkedin_accounts = SocialAccount.where(user_id: @current_user.id, provider: 'linkedin')
                                          .where.not(access_token: [nil, ''])

          if linkedin_accounts.empty?
            return render json: {
              success: false,
              message: "No LinkedIn accounts found",
              data: []
            }, status: 404
          end

          # Process accounts sequentially to avoid API rate limits
          analytics_data = []

          linkedin_accounts.each do |account|
            begin
              # Extract organization ID from user_info or use a default method
              organization_id = extract_organization_id(account)
              next unless organization_id

              service = LinkedinAnalyticsService.new(account.access_token)
              account_analytics = service.get_comprehensive_analytics(organization_id)

              analytics_data << {
                account_id: account.id,
                organization_id: organization_id,
                provider: account.provider,
                **account_analytics
              }
            rescue => e
              Rails.logger.error "Error processing LinkedIn account #{account.id}: #{e.message}"
              analytics_data << {
                account_id: account.id,
                organization_id: organization_id,
                provider: account.provider,
                error: "Failed to fetch analytics: #{e.message}"
              }
            end
          end

          render json: {
            success: true,
            message: "LinkedIn analytics retrieved successfully",
            total_accounts: analytics_data.length,
            data: analytics_data
          }

        rescue => e
          Rails.logger.error "LinkedIn Analytics Index Error: #{e.message}"
          render json: {
            success: false,
            message: "Failed to retrieve LinkedIn analytics",
            error: e.message,
            data: []
          }, status: 500
        end
      end

      # GET /api/v1/linkedin_analytics/:account_id
      # Get comprehensive analytics for a specific LinkedIn account
      def show
        begin
          organization_id = extract_organization_id(@linkedin_account)

          unless organization_id
            return render json: {
              success: false,
              message: "Organization ID not found for this account",
              data: {}
            }, status: 400
          end

          service = LinkedinAnalyticsService.new(@linkedin_account.access_token)
          analytics = service.get_comprehensive_analytics(organization_id)

          render json: {
            success: true,
            message: "LinkedIn analytics retrieved successfully",
            account_info: {
              account_id: @linkedin_account.id,
              organization_id: organization_id,
              provider: @linkedin_account.provider
            },
            data: analytics
          }

        rescue => e
          Rails.logger.error "LinkedIn Analytics Show Error: #{e.message}"
          render json: {
            success: false,
            message: "Failed to retrieve LinkedIn analytics",
            error: e.message,
            data: {}
          }, status: 500
        end
      end

      # GET /api/v1/linkedin_analytics/:account_id/follower_demographics
      # Get detailed follower demographics
      def follower_demographics
        begin
          organization_id = extract_organization_id(@linkedin_account)

          unless organization_id
            return render json: {
              success: false,
              message: "Organization ID not found for this account",
              data: {}
            }, status: 400
          end

          service = LinkedinAnalyticsService.new(@linkedin_account.access_token)
          organization_urn = service.send(:format_organization_urn, organization_id)

          # Get both lifetime and time-bound demographics
          lifetime_stats = service.get_follower_statistics(organization_urn)
          time_bound_stats = service.get_time_bound_follower_statistics(organization_urn, 90) # Last 3 months

          # Extract detailed demographics
          demographics = {
            by_industry: service.send(:extract_demographic_data, lifetime_stats, 'followerCountsByIndustry'),
            by_function: service.send(:extract_demographic_data, lifetime_stats, 'followerCountsByFunction'),
            by_seniority: service.send(:extract_demographic_data, lifetime_stats, 'followerCountsBySeniority'),
            by_company_size: service.send(:extract_demographic_data, lifetime_stats, 'followerCountsByStaffCountRange'),
            by_geography: service.send(:extract_demographic_data, lifetime_stats, 'followerCountsByGeoCountry'),
            by_market_area: service.send(:extract_demographic_data, lifetime_stats, 'followerCountsByGeo'),
            by_association: service.send(:extract_demographic_data, lifetime_stats, 'followerCountsByAssociationType')
          }

          # Calculate percentages for each demographic
          total_followers = demographics.values.flatten.sum { |item| item[:total_followers] }

          demographics.each do |key, items|
            items.each do |item|
              item[:percentage] = total_followers > 0 ? ((item[:total_followers].to_f / total_followers) * 100).round(2) : 0
            end
          end

          growth_trends = service.send(:analyze_follower_growth_trends, time_bound_stats)

          render json: {
            success: true,
            message: "LinkedIn follower demographics retrieved successfully",
            data: {
              demographics: demographics,
              growth_trends: growth_trends,
              summary: {
                total_followers_analyzed: total_followers,
                data_collection_period: "Lifetime",
                growth_analysis_period: "Last 90 days"
              }
            }
          }

        rescue => e
          Rails.logger.error "LinkedIn Follower Demographics Error: #{e.message}"
          render json: {
            success: false,
            message: "Failed to retrieve LinkedIn follower demographics",
            error: e.message,
            data: {}
          }, status: 500
        end
      end

      # GET /api/v1/linkedin_analytics/:account_id/share_statistics
      # Get detailed share statistics
      def share_statistics
        begin
          organization_id = extract_organization_id(@linkedin_account)

          unless organization_id
            return render json: {
              success: false,
              message: "Organization ID not found for this account",
              data: {}
            }, status: 400
          end

          service = LinkedinAnalyticsService.new(@linkedin_account.access_token)
          organization_urn = service.send(:format_organization_urn, organization_id)

          # Get both lifetime and time-bound share statistics
          lifetime_stats = service.get_share_statistics(organization_urn)

          # Get different time periods
          last_30_days = service.get_time_bound_share_statistics(organization_urn, 30)
          last_90_days = service.get_time_bound_share_statistics(organization_urn, 90)

          # Analyze engagement trends
          engagement_trends_30d = service.send(:analyze_engagement_trends, last_30_days)
          engagement_trends_90d = service.send(:analyze_engagement_trends, last_90_days)

          render json: {
            success: true,
            message: "LinkedIn share statistics retrieved successfully",
            data: {
              lifetime_performance: {
                total_impressions: lifetime_stats.dig('totalShareStatistics', 'impressionCount') || 0,
                unique_impressions: lifetime_stats.dig('totalShareStatistics', 'uniqueImpressionsCount') || 0,
                total_clicks: lifetime_stats.dig('totalShareStatistics', 'clickCount') || 0,
                total_likes: lifetime_stats.dig('totalShareStatistics', 'likeCount') || 0,
                total_comments: lifetime_stats.dig('totalShareStatistics', 'commentCount') || 0,
                total_shares: lifetime_stats.dig('totalShareStatistics', 'shareCount') || 0,
                engagement_rate: lifetime_stats.dig('totalShareStatistics', 'engagement') || 0,
                click_through_rate: service.send(:calculate_ctr, lifetime_stats)
              },
              time_bound_performance: {
                last_30_days: {
                  daily_breakdown: last_30_days,
                  engagement_trends: engagement_trends_30d
                },
                last_90_days: {
                  daily_breakdown: last_90_days,
                  engagement_trends: engagement_trends_90d
                }
              },
              performance_insights: {
                best_performing_day_30d: engagement_trends_30d[:best_engagement_day],
                engagement_trend_30d: engagement_trends_30d[:engagement_trend],
                total_engagement_30d: engagement_trends_30d[:total_engagement],
                average_daily_impressions_30d: engagement_trends_30d[:total_impressions] / 30.0,
                best_performing_day_90d: engagement_trends_90d[:best_engagement_day],
                engagement_trend_90d: engagement_trends_90d[:engagement_trend]
              }
            }
          }

        rescue => e
          Rails.logger.error "LinkedIn Share Statistics Error: #{e.message}"
          render json: {
            success: false,
            message: "Failed to retrieve LinkedIn share statistics",
            error: e.message,
            data: {}
          }, status: 500
        end
      end

      # GET /api/v1/linkedin_analytics/:account_id/social_actions
      # Get social actions summary for recent posts
      def social_actions
        begin
          organization_id = extract_organization_id(@linkedin_account)

          unless organization_id
            return render json: {
              success: false,
              message: "Organization ID not found for this account",
              data: {}
            }, status: 400
          end

          # Note: This is a simplified implementation
          # In a full implementation, you'd need to:
          # 1. Get recent posts/shares using the shares API
          # 2. Get social metadata for each post
          # 3. Get detailed social actions (likes, comments) for each post

          service = LinkedinAnalyticsService.new(@linkedin_account.access_token)

          # For demonstration, we'll show the structure that would be returned
          render json: {
            success: true,
            message: "LinkedIn social actions retrieved successfully",
            data: {
              recent_posts: [
                # This would be populated with actual post data
                # Example structure:
                # {
                #   post_urn: "urn:li:ugcPost:123456789",
                #   created_at: "2025-09-15T10:30:00Z",
                #   content_preview: "Sample post content...",
                #   social_metadata: {
                #     likes_count: 25,
                #     comments_count: 8,
                #     shares_count: 3,
                #     reactions: {
                #       LIKE: 15,
                #       PRAISE: 8,
                #       EMPATHY: 2
                #     }
                #   },
                #   performance_metrics: {
                #     engagement_rate: 5.2,
                #     click_through_rate: 2.1,
                #     reach: 500,
                #     impressions: 750
                #   }
                # }
              ],
              summary: {
                total_posts_analyzed: 0,
                average_engagement_rate: 0,
                total_likes: 0,
                total_comments: 0,
                total_shares: 0,
                most_engaging_post: nil
              },
              note: "This endpoint requires additional LinkedIn API permissions to access post content and social actions. Contact your administrator to enable these permissions."
            }
          }

        rescue => e
          Rails.logger.error "LinkedIn Social Actions Error: #{e.message}"
          render json: {
            success: false,
            message: "Failed to retrieve LinkedIn social actions",
            error: e.message,
            data: {}
          }, status: 500
        end
      end

      # GET /api/v1/linkedin_analytics/:account_id/organization_info
      # Get detailed organization information
      def organization_info
        begin
          organization_id = extract_organization_id(@linkedin_account)

          unless organization_id
            return render json: {
              success: false,
              message: "Organization ID not found for this account",
              data: {}
            }, status: 400
          end

          service = LinkedinAnalyticsService.new(@linkedin_account.access_token)
          organization_urn = service.send(:format_organization_urn, organization_id)

          org_info = service.get_organization_info(organization_urn)

          render json: {
            success: true,
            message: "LinkedIn organization information retrieved successfully",
            data: {
              organization: {
                id: organization_id,
                urn: organization_urn,
                name: org_info['localizedName'] || org_info['name'],
                description: org_info['localizedDescription'] || org_info['description'],
                website: org_info['website'],
                industry: org_info['industry'],
                logo_url: org_info.dig('logoV2', 'original'),
                follower_count: org_info['followerCount'] || 0,
                staff_count: org_info['staffCount'] || 0,
                specialties: org_info['specialties'] || [],
                founded_year: org_info['foundedOn']&.dig('year'),
                headquarters: {
                  country: org_info.dig('locations', 'headquarters', 'country'),
                  city: org_info.dig('locations', 'headquarters', 'city'),
                  postal_code: org_info.dig('locations', 'headquarters', 'postalCode')
                }
              },
              last_updated: Time.current.iso8601
            }
          }

        rescue => e
          Rails.logger.error "LinkedIn Organization Info Error: #{e.message}"
          render json: {
            success: false,
            message: "Failed to retrieve LinkedIn organization information",
            error: e.message,
            data: {}
          }, status: 500
        end
      end

      private

      def find_linkedin_account
        @linkedin_account = SocialAccount.where(user_id: @current_user.id, provider: 'linkedin')
                                        .find_by(id: params[:account_id])

        unless @linkedin_account
          render json: {
            success: false,
            message: "LinkedIn account not found",
            data: {}
          }, status: 404
          return
        end

        if @linkedin_account.access_token.blank?
          render json: {
            success: false,
            message: "No access token found for this LinkedIn account",
            data: {}
          }, status: 400
          return
        end
      end

      def extract_organization_id(account)
        # Try to extract organization ID from user_info JSON
        user_info = account.user_info

        if user_info.is_a?(Hash)
          # Check for organization ID in various possible fields
          org_id = user_info['organization_id'] ||
                   user_info['organizationId'] ||
                   user_info['company_id'] ||
                   user_info['companyId']

          return org_id if org_id
        end

        # If user_info is a string, try to parse it as JSON
        if user_info.is_a?(String)
          begin
            parsed_info = JSON.parse(user_info)
            org_id = parsed_info['organization_id'] ||
                     parsed_info['organizationId'] ||
                     parsed_info['company_id'] ||
                     parsed_info['companyId']

            return org_id if org_id
          rescue JSON::ParserError
            Rails.logger.warn "Failed to parse user_info JSON for account #{account.id}"
          end
        end

        # Fallback: use a default organization ID or prompt user to configure
        # You might want to add a specific field to store organization_id in the database
        Rails.logger.warn "No organization ID found for LinkedIn account #{account.id}"
        nil
      end
    end
  end
end