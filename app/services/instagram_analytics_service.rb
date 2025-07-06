require 'net/http'
require 'json'
require 'uri'

class InstagramAnalyticsService
  attr_reader :access_token, :base_url

  def initialize(access_token)
    @access_token = access_token
    @base_url = "https://graph.facebook.com/v18.0"
  end

  # Get user profile data
  def get_user_profile(user_id)
    uri = URI("#{@base_url}/#{user_id}")
    params = {
      access_token: @access_token,
      fields: "id,username,media_count,biography,followers_count,follows_count,profile_picture_url"
    }
    uri.query = URI.encode_www_form(params)
    
    response = Net::HTTP.get_response(uri)
    return {} if response.code != '200'
    
    JSON.parse(response.body)
  rescue => e
    Rails.logger.error "Instagram Profile Error: #{e.message}"
    {}
  end

  # Get user's media
  def get_user_media(user_id, limit = 25)
    uri = URI("#{@base_url}/#{user_id}/media")
    params = {
      access_token: @access_token,
      fields: "id,media_type,media_url,thumbnail_url,permalink,timestamp,caption,like_count,comments_count",
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

  # Get specific media details
  def get_media_details(media_id)
    uri = URI("#{@base_url}/#{media_id}")
    params = {
      access_token: @access_token,
      fields: "id,media_type,media_url,thumbnail_url,permalink,timestamp,caption,like_count,comments_count,username"
    }
    uri.query = URI.encode_www_form(params)
    
    response = Net::HTTP.get_response(uri)
    return {} if response.code != '200'
    
    JSON.parse(response.body)
  rescue => e
    Rails.logger.error "Instagram Media Details Error: #{e.message}"
    {}
  end

  # Analyze user's content
  def analyze_user_content(user_id)
    media_data = get_user_media(user_id, 100)
    
    return default_analytics if media_data['data'].blank?
    
    analysis = {
      total_posts: media_data['data'].length,
      media_types: {},
      recent_posts: [],
      posting_frequency: {},
      engagement_stats: {},
      top_performing_posts: []
    }
    
    total_likes = 0
    total_comments = 0
    
    media_data['data'].each do |media|
      # Count media types
      media_type = media['media_type']
      analysis[:media_types][media_type] = (analysis[:media_types][media_type] || 0) + 1
      
      # Calculate engagement
      likes = media['like_count'] || 0
      comments = media['comments_count'] || 0
      total_likes += likes
      total_comments += comments
      
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
    
    analysis
  rescue => e
    Rails.logger.error "Instagram Analytics Error: #{e.message}"
    default_analytics
  end

  # Get comprehensive analytics for a user
  def get_comprehensive_analytics(user_id)
    profile = get_user_profile(user_id)
    return default_comprehensive_analytics if profile.blank?
    
    analytics = analyze_user_content(user_id)
    
    # Calculate engagement rate
    followers = profile['followers_count'] || 1
    avg_engagement = analytics[:engagement_stats][:average_engagement_per_post] || 0
    engagement_rate = followers > 0 ? ((avg_engagement.to_f / followers) * 100).round(2) : 0
    
    {
      profile: {
        id: profile['id'],
        username: profile['username'],
        biography: profile['biography'],
        followers_count: profile['followers_count'] || 0,
        follows_count: profile['follows_count'] || 0,
        media_count: profile['media_count'] || 0,
        profile_picture_url: profile['profile_picture_url'],
        engagement_rate: engagement_rate
      },
      analytics: analytics,
      summary: {
        total_posts: analytics[:total_posts],
        total_engagement: analytics[:engagement_stats][:total_engagement],
        engagement_rate: "#{engagement_rate}%",
        most_used_media_type: analytics[:media_types].max_by { |_, count| count }&.first || 'N/A',
        posting_frequency: calculate_posting_frequency(analytics[:posting_frequency])
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