require 'net/http'
require 'json'
require 'uri'

class InstagramAnalyticsService
  attr_reader :access_token, :base_url

  def initialize(access_token)
    @access_token = access_token
    @base_url = "https://graph.facebook.com/v18.0"
  end

  # Check if this is a Facebook Page with Instagram account
  def get_page_instagram_account(page_id)
    uri = URI("#{@base_url}/#{page_id}")
    params = {
      access_token: @access_token,
      fields: "instagram_business_account"
    }
    uri.query = URI.encode_www_form(params)

    Rails.logger.info "Checking Instagram account for page: #{page_id}"
    response = Net::HTTP.get_response(uri)

    if response.code != '200'
      Rails.logger.warn "Page lookup failed with code #{response.code}: #{response.body}"
      return nil
    end

    data = JSON.parse(response.body)
    instagram_id = data.dig('instagram_business_account', 'id')

    if instagram_id
      Rails.logger.info "Found Instagram account ID: #{instagram_id}"
    else
      Rails.logger.info "No Instagram account found for page #{page_id}"
    end

    instagram_id
  rescue => e
    Rails.logger.error "Page Instagram Account Error: #{e.message}"
    Rails.logger.error "Response: #{response&.body}"
    nil
  end

  # Get Instagram Business Account profile data
  def get_instagram_profile(instagram_account_id)
    uri = URI("#{@base_url}/#{instagram_account_id}")
    params = {
      access_token: @access_token,
      fields: "id,username,name,biography,followers_count,follows_count,media_count,profile_picture_url,website"
    }
    uri.query = URI.encode_www_form(params)

    response = Net::HTTP.get_response(uri)
    return {} if response.code != '200'

    JSON.parse(response.body)
  rescue => e
    Rails.logger.error "Instagram Profile Error: #{e.message}"
    {}
  end

  # Get user profile data (updated to handle both page and Instagram accounts)
  def get_user_profile(user_id)
    # First try to get Instagram account from page
    instagram_account_id = get_page_instagram_account(user_id)

    if instagram_account_id
      # This is a Facebook Page with Instagram account
      get_instagram_profile(instagram_account_id)
    else
      # Try direct Instagram account access
      get_instagram_profile(user_id)
    end
  end

  # Get Instagram account's media
  def get_user_media(user_id, limit = 25)
    # First try to get Instagram account from page
    instagram_account_id = get_page_instagram_account(user_id) || user_id

    uri = URI("#{@base_url}/#{instagram_account_id}/media")
    params = {
      access_token: @access_token,
      fields: "id,media_type,media_url,thumbnail_url,permalink,timestamp,caption,like_count,comments_count,reach,impressions,saved",
      limit: limit
    }
    uri.query = URI.encode_www_form(params)

    response = Net::HTTP.get_response(uri)
    return { 'data' => [] } if response.code != '200'

    JSON.parse(response.body)
  rescue => e
    Rails.logger.error "Instagram Media Error: #{e.message}"
    { 'data' => [] }
  end

  # Get specific media details with insights
  def get_media_details(media_id)
    uri = URI("#{@base_url}/#{media_id}")
    params = {
      access_token: @access_token,
      fields: "id,media_type,media_url,thumbnail_url,permalink,timestamp,caption,like_count,comments_count,username"
    }
    uri.query = URI.encode_www_form(params)

    response = Net::HTTP.get_response(uri)
    return {} if response.code != '200'

    media_data = JSON.parse(response.body)

    # Get media insights
    insights = get_media_insights(media_id)
    media_data['insights'] = insights if insights.any?

    media_data
  rescue => e
    Rails.logger.error "Instagram Media Details Error: #{e.message}"
    {}
  end

  # Get media insights (engagement metrics)
  def get_media_insights(media_id)
    uri = URI("#{@base_url}/#{media_id}/insights")
    params = {
      access_token: @access_token,
      metric: "engagement,impressions,reach,saved,video_views,profile_visits,website_clicks"
    }
    uri.query = URI.encode_www_form(params)

    response = Net::HTTP.get_response(uri)
    return {} if response.code != '200'

    data = JSON.parse(response.body)
    insights = {}

    data['data']&.each do |insight|
      insights[insight['name']] = insight['values']&.first&.dig('value') || 0
    end

    insights
  rescue => e
    Rails.logger.error "Instagram Media Insights Error: #{e.message}"
    {}
  end

  # Get Instagram account insights (followers demographics, reach, impressions)
  def get_account_insights(instagram_account_id, period = 'day', since_date = nil, until_date = nil)
    uri = URI("#{@base_url}/#{instagram_account_id}/insights")

    # Default to last 30 days if no dates provided
    since_date ||= (Date.current - 30.days).strftime('%Y-%m-%d')
    until_date ||= Date.current.strftime('%Y-%m-%d')

    params = {
      access_token: @access_token,
      metric: "follower_count,get_directions_clicks,phone_call_clicks,text_message_clicks,website_clicks,email_contacts,profile_views,reach,impressions",
      period: period,
      since: since_date,
      until: until_date
    }
    uri.query = URI.encode_www_form(params)

    response = Net::HTTP.get_response(uri)
    return {} if response.code != '200'

    data = JSON.parse(response.body)
    insights = {}

    data['data']&.each do |insight|
      metric_name = insight['name']
      values = insight['values'] || []

      # Calculate total and average for the period
      total_value = values.sum { |v| v['value'].to_i }
      avg_value = values.any? ? (total_value.to_f / values.length).round(2) : 0

      insights[metric_name] = {
        total: total_value,
        average: avg_value,
        values: values
      }
    end

    insights
  rescue => e
    Rails.logger.error "Instagram Account Insights Error: #{e.message}"
    {}
  end

  # Get demographic insights for followers
  def get_follower_demographics(instagram_account_id)
    uri = URI("#{@base_url}/#{instagram_account_id}/insights")
    params = {
      access_token: @access_token,
      metric: "audience_gender_age,audience_locale,audience_country,audience_city",
      period: "lifetime"
    }
    uri.query = URI.encode_www_form(params)

    response = Net::HTTP.get_response(uri)
    return {} if response.code != '200'

    data = JSON.parse(response.body)
    demographics = {}

    data['data']&.each do |insight|
      metric_name = insight['name']
      value = insight['values']&.first&.dig('value') || {}
      demographics[metric_name] = value
    end

    demographics
  rescue => e
    Rails.logger.error "Instagram Demographics Error: #{e.message}"
    {}
  end

  # Analyze user's content with enhanced insights
  def analyze_user_content(user_id)
    media_data = get_user_media(user_id, 100)

    return default_analytics if media_data['data'].blank?

    analysis = {
      total_posts: media_data['data'].length,
      media_types: {},
      recent_posts: [],
      posting_frequency: {},
      engagement_stats: {},
      top_performing_posts: [],
      reach_stats: {},
      impressions_stats: {}
    }

    total_likes = 0
    total_comments = 0
    total_reach = 0
    total_impressions = 0
    total_saved = 0
    reach_count = 0
    impressions_count = 0
    saved_count = 0

    media_data['data'].each do |media|
      # Count media types
      media_type = media['media_type']
      analysis[:media_types][media_type] = (analysis[:media_types][media_type] || 0) + 1

      # Calculate engagement
      likes = media['like_count'] || 0
      comments = media['comments_count'] || 0
      reach = media['reach'] || 0
      impressions = media['impressions'] || 0
      saved = media['saved'] || 0

      total_likes += likes
      total_comments += comments

      if reach > 0
        total_reach += reach
        reach_count += 1
      end

      if impressions > 0
        total_impressions += impressions
        impressions_count += 1
      end

      if saved > 0
        total_saved += saved
        saved_count += 1
      end

      # Get recent posts (last 10)
      if analysis[:recent_posts].length < 10
        analysis[:recent_posts] << {
          id: media['id'],
          type: media['media_type'],
          url: media['permalink'],
          media_url: media['media_url'],
          thumbnail_url: media['thumbnail_url'],
          caption: media['caption']&.truncate(100),
          timestamp: media['timestamp'],
          likes: likes,
          comments: comments,
          reach: reach,
          impressions: impressions,
          saved: saved,
          engagement: likes + comments
        }
      end

      # Track top performing posts
      engagement_score = likes + comments
      analysis[:top_performing_posts] << {
        id: media['id'],
        url: media['permalink'],
        media_url: media['media_url'],
        thumbnail_url: media['thumbnail_url'],
        caption: media['caption']&.truncate(100),
        timestamp: media['timestamp'],
        likes: likes,
        comments: comments,
        reach: reach,
        impressions: impressions,
        saved: saved,
        engagement: engagement_score
      }

      # Analyze posting frequency by month
      if media['timestamp']
        begin
          date = Date.parse(media['timestamp'])
          month_key = date.strftime("%Y-%m")
          analysis[:posting_frequency][month_key] = (analysis[:posting_frequency][month_key] || 0) + 1
        rescue
          # Skip invalid dates
        end
      end
    end

    # Sort top performing posts by engagement
    analysis[:top_performing_posts] = analysis[:top_performing_posts]
                                       .sort_by { |post| -post[:engagement] }
                                       .first(5)

    # Calculate engagement statistics
    analysis[:engagement_stats] = {
      total_likes: total_likes,
      total_comments: total_comments,
      total_engagement: total_likes + total_comments,
      average_likes_per_post: analysis[:total_posts] > 0 ? (total_likes.to_f / analysis[:total_posts]).round(2) : 0,
      average_comments_per_post: analysis[:total_posts] > 0 ? (total_comments.to_f / analysis[:total_posts]).round(2) : 0,
      average_engagement_per_post: analysis[:total_posts] > 0 ? ((total_likes + total_comments).to_f / analysis[:total_posts]).round(2) : 0
    }

    # Calculate reach and impressions statistics
    analysis[:reach_stats] = {
      total_reach: total_reach,
      average_reach_per_post: reach_count > 0 ? (total_reach.to_f / reach_count).round(2) : 0,
      posts_with_reach_data: reach_count
    }

    analysis[:impressions_stats] = {
      total_impressions: total_impressions,
      average_impressions_per_post: impressions_count > 0 ? (total_impressions.to_f / impressions_count).round(2) : 0,
      posts_with_impressions_data: impressions_count
    }

    analysis[:saved_stats] = {
      total_saved: total_saved,
      average_saved_per_post: saved_count > 0 ? (total_saved.to_f / saved_count).round(2) : 0,
      posts_with_saved_data: saved_count
    }

    analysis
  rescue => e
    Rails.logger.error "Instagram Analytics Error: #{e.message}"
    default_analytics
  end

  # Get comprehensive analytics for a user
  def get_comprehensive_analytics(user_id)
    profile = get_user_profile(user_id)
    return default_comprehensive_analytics if profile.blank?

    # Get Instagram account ID
    instagram_account_id = get_page_instagram_account(user_id) || user_id

    # Get all analytics data
    analytics = analyze_user_content(user_id)
    account_insights = get_account_insights(instagram_account_id)
    demographics = get_follower_demographics(instagram_account_id)

    # Calculate engagement rate
    followers = profile['followers_count'] || 1
    avg_engagement = analytics[:engagement_stats][:average_engagement_per_post] || 0
    engagement_rate = followers > 0 ? ((avg_engagement.to_f / followers) * 100).round(2) : 0

    # Get reach and impressions data
    reach_data = account_insights['reach'] || {}
    impressions_data = account_insights['impressions'] || {}
    profile_views_data = account_insights['profile_views'] || {}

    {
      profile: {
        id: profile['id'],
        username: profile['username'],
        name: profile['name'],
        biography: profile['biography'],
        followers_count: profile['followers_count'] || 0,
        follows_count: profile['follows_count'] || 0,
        media_count: profile['media_count'] || 0,
        profile_picture_url: profile['profile_picture_url'],
        website: profile['website'],
        engagement_rate: engagement_rate
      },
      analytics: analytics,
      insights: {
        reach: reach_data,
        impressions: impressions_data,
        profile_views: profile_views_data,
        website_clicks: account_insights['website_clicks'] || {},
        email_contacts: account_insights['email_contacts'] || {},
        phone_call_clicks: account_insights['phone_call_clicks'] || {},
        text_message_clicks: account_insights['text_message_clicks'] || {},
        get_directions_clicks: account_insights['get_directions_clicks'] || {}
      },
      demographics: {
        gender_age: demographics['audience_gender_age'] || {},
        locations: {
          countries: demographics['audience_country'] || {},
          cities: demographics['audience_city'] || {}
        },
        locales: demographics['audience_locale'] || {}
      },
      summary: {
        total_posts: analytics[:total_posts],
        total_engagement: analytics[:engagement_stats][:total_engagement],
        engagement_rate: "#{engagement_rate}%",
        most_used_media_type: analytics[:media_types].max_by { |_, count| count }&.first || 'N/A',
        posting_frequency: calculate_posting_frequency(analytics[:posting_frequency]),
        avg_reach: reach_data['average'] || 0,
        avg_impressions: impressions_data['average'] || 0,
        avg_profile_views: profile_views_data['average'] || 0
      },
      collected_at: Time.current.iso8601
    }
  end

  private

  def default_analytics
    {
      total_posts: 0,
      media_types: {},
      recent_posts: [],
      posting_frequency: {},
      engagement_stats: {
        total_likes: 0,
        total_comments: 0,
        total_engagement: 0,
        average_likes_per_post: 0,
        average_comments_per_post: 0,
        average_engagement_per_post: 0
      },
      reach_stats: {
        total_reach: 0,
        average_reach_per_post: 0,
        posts_with_reach_data: 0
      },
      impressions_stats: {
        total_impressions: 0,
        average_impressions_per_post: 0,
        posts_with_impressions_data: 0
      },
      saved_stats: {
        total_saved: 0,
        average_saved_per_post: 0,
        posts_with_saved_data: 0
      },
      top_performing_posts: []
    }
  end

  def default_comprehensive_analytics
    {
      profile: {
        id: nil,
        username: nil,
        biography: nil,
        followers_count: 0,
        follows_count: 0,
        media_count: 0,
        profile_picture_url: nil,
        engagement_rate: 0
      },
      analytics: default_analytics,
      summary: {
        total_posts: 0,
        total_engagement: 0,
        engagement_rate: "0%",
        most_used_media_type: 'N/A',
        posting_frequency: 'No data'
      },
      collected_at: Time.current.iso8601
    }
  end

  def calculate_posting_frequency(frequency_data)
    return 'No data' if frequency_data.blank?
    
    months = frequency_data.keys.sort
    return 'No data' if months.empty?
    
    if months.length == 1
      "#{frequency_data[months.first]} posts in #{months.first}"
    else
      total_posts = frequency_data.values.sum
      avg_per_month = (total_posts.to_f / months.length).round(1)
      "#{avg_per_month} posts per month (avg)"
    end
  end
end