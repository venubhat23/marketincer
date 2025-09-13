require 'net/http'
require 'json'
require 'uri'

class InstagramAnalyticsServiceV2
  attr_reader :access_token, :base_url

  def initialize(access_token)
    @access_token = access_token
    @base_url = "https://graph.facebook.com/v18.0"
  end

  # Make API request with error handling
  def make_api_request(endpoint, description = "API call")
    uri = URI(endpoint)
    response = Net::HTTP.get_response(uri)
    
    Rails.logger.info "Instagram API: #{description} - Status: #{response.code}"
    
    if response.code == '200'
      data = JSON.parse(response.body)
      Rails.logger.info "Success: Got #{data['data']&.length || 'data'} items"
      data
    else
      error_data = JSON.parse(response.body) rescue response.body
      Rails.logger.error "API Error: #{error_data.dig('error', 'message') || error_data}"
      nil
    end
  rescue => e
    Rails.logger.error "Exception in #{description}: #{e.message}"
    nil
  end

  # Get Instagram Business Account ID from page
  def get_instagram_business_account(page_id)
    endpoint = "#{@base_url}/#{page_id}?access_token=#{@access_token}&fields=instagram_business_account"
    response = make_api_request(endpoint, "Getting Instagram Business Account")
    
    if response && response['instagram_business_account']
      response['instagram_business_account']['id']
    else
      # Try direct lookup
      endpoint = "#{@base_url}/#{page_id}/instagram_accounts?access_token=#{@access_token}"
      response = make_api_request(endpoint, "Getting Instagram accounts via lookup")
      
      if response && response['data'] && response['data'].any?
        response['data'].first['id']
      else
        page_id # Use original page_id as fallback
      end
    end
  end

  # Get comprehensive profile data
  def get_profile_data(instagram_account_id)
    profile_fields = "id,username,name,biography,followers_count,follows_count,media_count,profile_picture_url,website"
    endpoint = "#{@base_url}/#{instagram_account_id}?access_token=#{@access_token}&fields=#{profile_fields}"
    
    make_api_request(endpoint, "Getting profile data")
  end

  # Get media data with pagination
  def get_media_data(instagram_account_id, limit = 50)
    media_fields = "id,media_type,media_url,permalink,timestamp,caption,like_count,comments_count,media_product_type,username"
    endpoint = "#{@base_url}/#{instagram_account_id}/media?access_token=#{@access_token}&fields=#{media_fields}&limit=#{limit}"
    
    media_data = make_api_request(endpoint, "Getting media data")
    return { 'data' => [] } unless media_data
    
    # Get all media with pagination
    all_media = media_data['data'] || []
    next_url = media_data.dig('paging', 'next')
    
    page_count = 1
    while next_url && page_count < 10  # Limit to 10 pages
      Rails.logger.info "Fetching media page #{page_count + 1}"
      more_data = make_api_request(next_url, "Getting more media")
      break unless more_data && more_data['data']
      
      all_media += more_data['data']
      next_url = more_data.dig('paging', 'next')
      page_count += 1
    end
    
    { 'data' => all_media, 'total' => all_media.length }
  end

  # Get insights data
  def get_insights_data(instagram_account_id, days = 30)
    insights_results = {}
    
    # Calculate date range
    end_date = Date.current
    start_date = end_date - days.days
    start_date_str = start_date.strftime('%Y-%m-%d')
    end_date_str = end_date.strftime('%Y-%m-%d')

    # Profile views
    endpoint = "#{@base_url}/#{instagram_account_id}/insights?access_token=#{@access_token}&metric=profile_views&period=day&metric_type=total_value&since=#{start_date_str}&until=#{end_date_str}"
    profile_views_data = make_api_request(endpoint, "Getting profile views")
    
    if profile_views_data && profile_views_data['data'] && profile_views_data['data'].any?
      total_profile_views = profile_views_data['data'].first['values'].sum { |v| v['value'] || 0 }
      insights_results[:profile_views] = total_profile_views
    end

    # Reach
    endpoint = "#{@base_url}/#{instagram_account_id}/insights?access_token=#{@access_token}&metric=reach&period=day&since=#{start_date_str}&until=#{end_date_str}"
    reach_data = make_api_request(endpoint, "Getting reach data")
    
    if reach_data && reach_data['data'] && reach_data['data'].any?
      total_reach = reach_data['data'].first['values'].sum { |v| v['value'] || 0 }
      insights_results[:reach] = total_reach
    end

    # Impressions
    endpoint = "#{@base_url}/#{instagram_account_id}/insights?access_token=#{@access_token}&metric=impressions&period=day&since=#{start_date_str}&until=#{end_date_str}"
    impressions_data = make_api_request(endpoint, "Getting impressions data")
    
    if impressions_data && impressions_data['data'] && impressions_data['data'].any?
      total_impressions = impressions_data['data'].first['values'].sum { |v| v['value'] || 0 }
      insights_results[:impressions] = total_impressions
    end

    # Follower count (lifetime metric)
    endpoint = "#{@base_url}/#{instagram_account_id}/insights?access_token=#{@access_token}&metric=follower_count&period=lifetime"
    follower_data = make_api_request(endpoint, "Getting follower count")
    
    if follower_data && follower_data['data'] && follower_data['data'].any?
      current_followers = follower_data['data'].first['values'].last['value'] rescue 0
      insights_results[:follower_count] = current_followers
    end

    # Demographic data (requires 100+ followers)
    if insights_results[:follower_count] && insights_results[:follower_count] >= 100
      demo_metrics = ["audience_gender_age", "audience_locale", "audience_country"]
      
      demo_metrics.each do |metric|
        endpoint = "#{@base_url}/#{instagram_account_id}/insights?access_token=#{@access_token}&metric=#{metric}&period=lifetime"
        demo_data = make_api_request(endpoint, "Getting #{metric} data")
        
        if demo_data && demo_data['data'] && demo_data['data'].any?
          metric_data = demo_data['data'].first
          if metric_data['values'] && metric_data['values'].any?
            demographic_data = metric_data['values'].first['value']
            insights_results[metric.to_sym] = demographic_data if demographic_data.is_a?(Hash)
          end
        end
      end
    end

    {
      insights: insights_results,
      period: {
        start_date: start_date_str,
        end_date: end_date_str,
        days: days
      }
    }
  end

  # Get individual media insights
  def get_media_insights(media_id)
    post_metrics = "impressions,reach,likes,comments,saved,shares"
    endpoint = "#{@base_url}/#{media_id}/insights?access_token=#{@access_token}&metric=#{post_metrics}"
    
    insights_data = make_api_request(endpoint, "Getting media insights")
    return {} unless insights_data && insights_data['data']

    post_analytics = {}
    insights_data['data'].each do |insight|
      metric_name = insight['name']
      metric_value = insight['values']&.first&.dig('value') || 0
      post_analytics[metric_name] = metric_value
    end
    
    post_analytics
  end

  # Analyze content patterns
  def analyze_content(media_data)
    return default_content_analysis if !media_data || media_data['data'].blank?

    all_media = media_data['data']
    
    analysis = {
      total_posts: all_media.length,
      media_types: {},
      engagement_stats: {},
      posting_patterns: {},
      content_analysis: {}
    }

    # Media type distribution
    analysis[:media_types] = all_media.group_by { |m| m['media_type'] }.transform_values(&:count)

    # Engagement statistics
    posts_with_engagement = all_media.select { |m| (m['like_count'] || 0) > 0 || (m['comments_count'] || 0) > 0 }
    
    if posts_with_engagement.any?
      total_likes = all_media.sum { |m| m['like_count'] || 0 }
      total_comments = all_media.sum { |m| m['comments_count'] || 0 }
      
      analysis[:engagement_stats] = {
        total_likes: total_likes,
        total_comments: total_comments,
        total_engagement: total_likes + total_comments,
        posts_with_engagement: posts_with_engagement.length,
        average_likes_per_post: (total_likes.to_f / all_media.length).round(2),
        average_comments_per_post: (total_comments.to_f / all_media.length).round(2),
        average_engagement_per_post: ((total_likes + total_comments).to_f / all_media.length).round(2)
      }
    else
      analysis[:engagement_stats] = default_engagement_stats
    end

    # Posting patterns
    if all_media.any? && all_media.first['timestamp']
      dates = all_media.filter_map { |m| Date.parse(m['timestamp']) rescue nil }
      
      if dates.any?
        # Monthly frequency
        monthly = dates.group_by { |d| d.strftime('%Y-%m') }.transform_values(&:count)
        
        # Day of week analysis
        daily = dates.group_by { |d| d.strftime('%A') }.transform_values(&:count)
        
        # Recent activity
        recent_posts = dates.select { |d| d >= 30.days.ago.to_date }
        
        analysis[:posting_patterns] = {
          monthly_frequency: monthly.sort.reverse.first(6).to_h,
          day_of_week: daily,
          recent_activity: {
            posts_last_30_days: recent_posts.length,
            average_posts_per_week: (recent_posts.length / 4.3).round(1)
          }
        }
      end
    end

    # Content analysis
    captions = all_media.select { |m| m['caption'] && !m['caption'].strip.empty? }
    
    if captions.any?
      caption_lengths = captions.map { |m| m['caption'].length }
      all_hashtags = captions.flat_map { |m| m['caption'].scan(/#\w+/) }
      
      analysis[:content_analysis] = {
        posts_with_captions: captions.length,
        average_caption_length: (caption_lengths.sum.to_f / caption_lengths.length).round(1),
        total_hashtags: all_hashtags.length,
        unique_hashtags: all_hashtags.uniq.length,
        top_hashtags: all_hashtags.group_by(&:itself).transform_values(&:count).sort_by { |_, count| -count }.first(10).to_h
      }
    else
      analysis[:content_analysis] = default_content_analysis
    end

    # Top performing posts
    if posts_with_engagement.any?
      analysis[:top_posts] = posts_with_engagement
        .sort_by { |m| (m['like_count'] || 0) + (m['comments_count'] || 0) }
        .reverse
        .first(5)
        .map do |post|
          {
            id: post['id'],
            media_type: post['media_type'],
            permalink: post['permalink'],
            timestamp: post['timestamp'],
            caption: post['caption']&.truncate(100),
            likes: post['like_count'] || 0,
            comments: post['comments_count'] || 0,
            total_engagement: (post['like_count'] || 0) + (post['comments_count'] || 0)
          }
        end
    else
      analysis[:top_posts] = []
    end

    analysis
  end

  # Get comprehensive analytics
  def get_comprehensive_analytics(page_id, options = {})
    instagram_account_id = get_instagram_business_account(page_id)
    days = options[:days] || 30
    media_limit = options[:media_limit] || 100

    begin
      # Get all data
      profile_data = get_profile_data(instagram_account_id)
      media_data = get_media_data(instagram_account_id, media_limit)
      insights_data = get_insights_data(instagram_account_id, days)
      content_analysis = analyze_content(media_data)

      # Calculate engagement rate
      engagement_rate = 0
      if profile_data && profile_data['followers_count'] && profile_data['followers_count'] > 0
        avg_engagement = content_analysis[:engagement_stats][:average_engagement_per_post] || 0
        engagement_rate = (avg_engagement / profile_data['followers_count'] * 100).round(2)
      end

      {
        account_info: {
          instagram_account_id: instagram_account_id,
          profile: profile_data,
          engagement_rate: engagement_rate
        },
        insights: insights_data,
        media_summary: {
          total_posts: media_data['total'] || 0,
          recent_posts: media_data['data']&.first(10) || []
        },
        analytics: content_analysis,
        metadata: {
          collected_at: Time.current.iso8601,
          api_version: "v18.0",
          data_period_days: days
        }
      }
    rescue => e
      Rails.logger.error "Comprehensive Analytics Error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      
      {
        error: true,
        message: e.message,
        account_info: { instagram_account_id: instagram_account_id },
        insights: { insights: {}, period: {} },
        media_summary: { total_posts: 0, recent_posts: [] },
        analytics: default_content_analysis,
        metadata: { collected_at: Time.current.iso8601, error: true }
      }
    end
  end

  private

  def default_content_analysis
    {
      total_posts: 0,
      media_types: {},
      engagement_stats: default_engagement_stats,
      posting_patterns: {},
      content_analysis: {},
      top_posts: []
    }
  end

  def default_engagement_stats
    {
      total_likes: 0,
      total_comments: 0,
      total_engagement: 0,
      posts_with_engagement: 0,
      average_likes_per_post: 0,
      average_comments_per_post: 0,
      average_engagement_per_post: 0
    }
  end
end