require 'net/http'
require 'json'
require 'uri'

class LinkedinAnalyticsService
  attr_reader :access_token, :base_url

  def initialize(access_token)
    @access_token = access_token
    @base_url = "https://api.linkedin.com/rest"
    @cache = {}
    @cache_ttl = 300 # 5 minutes
  end

  # Get comprehensive LinkedIn analytics for an organization
  def get_comprehensive_analytics(organization_id)
    begin
      organization_urn = format_organization_urn(organization_id)

      # Get all analytics data with individual error handling
      follower_stats = safe_execute { get_follower_statistics(organization_urn) } || {}
      share_stats = safe_execute { get_share_statistics(organization_urn) } || {}
      time_bound_follower_stats = safe_execute { get_time_bound_follower_statistics(organization_urn) } || {}
      time_bound_share_stats = safe_execute { get_time_bound_share_statistics(organization_urn) } || {}

      # Get organization basic info
      org_info = safe_execute { get_organization_info(organization_urn) } || {}

      {
        organization: {
          id: organization_id,
          urn: organization_urn,
          name: org_info['localizedName'] || org_info['name'],
          description: org_info['localizedDescription'] || org_info['description'],
          website: org_info['website'],
          industry: org_info['industry'],
          logo_url: org_info.dig('logoV2', 'original'),
          follower_count: org_info['followerCount'] || 0,
          staff_count: org_info['staffCount'] || 0
        },
        follower_analytics: {
          lifetime_demographics: follower_stats,
          time_bound_growth: time_bound_follower_stats,
          # Demographic breakdown
          demographics: {
            by_industry: extract_demographic_data(follower_stats, 'followerCountsByIndustry'),
            by_function: extract_demographic_data(follower_stats, 'followerCountsByFunction'),
            by_seniority: extract_demographic_data(follower_stats, 'followerCountsBySeniority'),
            by_company_size: extract_demographic_data(follower_stats, 'followerCountsByStaffCountRange'),
            by_geography: extract_demographic_data(follower_stats, 'followerCountsByGeoCountry'),
            by_market_area: extract_demographic_data(follower_stats, 'followerCountsByGeo'),
            by_association: extract_demographic_data(follower_stats, 'followerCountsByAssociationType')
          },
          growth_trends: analyze_follower_growth_trends(time_bound_follower_stats)
        },
        share_analytics: {
          lifetime_performance: share_stats,
          time_bound_performance: time_bound_share_stats,
          performance_summary: {
            total_impressions: share_stats.dig('totalShareStatistics', 'impressionCount') || 0,
            unique_impressions: share_stats.dig('totalShareStatistics', 'uniqueImpressionsCount') || 0,
            total_clicks: share_stats.dig('totalShareStatistics', 'clickCount') || 0,
            total_likes: share_stats.dig('totalShareStatistics', 'likeCount') || 0,
            total_comments: share_stats.dig('totalShareStatistics', 'commentCount') || 0,
            total_shares: share_stats.dig('totalShareStatistics', 'shareCount') || 0,
            engagement_rate: share_stats.dig('totalShareStatistics', 'engagement') || 0,
            click_through_rate: calculate_ctr(share_stats)
          },
          engagement_trends: analyze_engagement_trends(time_bound_share_stats)
        },
        summary: {
          total_followers: org_info['followerCount'] || 0,
          total_posts: calculate_total_posts(share_stats),
          avg_engagement_rate: share_stats.dig('totalShareStatistics', 'engagement') || 0,
          top_performing_content_type: analyze_top_content_type(time_bound_share_stats),
          best_posting_day: analyze_best_posting_day(time_bound_share_stats),
          follower_growth_rate: calculate_follower_growth_rate(time_bound_follower_stats)
        },
        collected_at: Time.current.iso8601
      }
    rescue => e
      Rails.logger.error "LinkedIn Comprehensive Analytics Error: #{e.message}"
      default_comprehensive_analytics
    end
  end

  # Get organization follower statistics (lifetime demographics)
  def get_follower_statistics(organization_urn)
    cache_key = "follower_stats_#{organization_urn}"

    # Check cache first
    if @cache[cache_key] && @cache[cache_key][:timestamp] && (Time.current - @cache[cache_key][:timestamp]) < @cache_ttl
      return @cache[cache_key][:data]
    end

    uri = URI("#{@base_url}/organizationalEntityFollowerStatistics")
    params = {
      q: 'organizationalEntity',
      organizationalEntity: organization_urn
    }
    uri.query = URI.encode_www_form(params)

    response = make_request(uri)
    return {} if response.nil?

    data = JSON.parse(response.body)
    follower_data = data['elements']&.first || {}

    @cache[cache_key] = { data: follower_data, timestamp: Time.current }
    follower_data
  rescue => e
    Rails.logger.error "LinkedIn Follower Statistics Error: #{e.message}"
    @cache[cache_key] = { data: {}, timestamp: Time.current }
    {}
  end

  # Get time-bound follower statistics (growth over time)
  def get_time_bound_follower_statistics(organization_urn, days_back = 30)
    cache_key = "time_follower_stats_#{organization_urn}_#{days_back}"

    # Check cache first
    if @cache[cache_key] && @cache[cache_key][:timestamp] && (Time.current - @cache[cache_key][:timestamp]) < @cache_ttl
      return @cache[cache_key][:data]
    end

    end_time = Time.current
    start_time = end_time - days_back.days

    uri = URI("#{@base_url}/organizationalEntityFollowerStatistics")
    params = {
      q: 'organizationalEntity',
      organizationalEntity: organization_urn,
      'timeIntervals.timeGranularityType' => 'DAY',
      'timeIntervals.timeRange.start' => (start_time.to_f * 1000).to_i,
      'timeIntervals.timeRange.end' => (end_time.to_f * 1000).to_i
    }
    uri.query = URI.encode_www_form(params)

    response = make_request(uri)
    return [] if response.nil?

    data = JSON.parse(response.body)
    growth_data = data['elements'] || []

    @cache[cache_key] = { data: growth_data, timestamp: Time.current }
    growth_data
  rescue => e
    Rails.logger.error "LinkedIn Time-bound Follower Statistics Error: #{e.message}"
    @cache[cache_key] = { data: [], timestamp: Time.current }
    []
  end

  # Get organization share statistics (lifetime)
  def get_share_statistics(organization_urn)
    cache_key = "share_stats_#{organization_urn}"

    # Check cache first
    if @cache[cache_key] && @cache[cache_key][:timestamp] && (Time.current - @cache[cache_key][:timestamp]) < @cache_ttl
      return @cache[cache_key][:data]
    end

    uri = URI("#{@base_url}/organizationalEntityShareStatistics")
    params = {
      q: 'organizationalEntity',
      organizationalEntity: organization_urn
    }
    uri.query = URI.encode_www_form(params)

    response = make_request(uri)
    return {} if response.nil?

    data = JSON.parse(response.body)
    share_data = data['elements']&.first || {}

    @cache[cache_key] = { data: share_data, timestamp: Time.current }
    share_data
  rescue => e
    Rails.logger.error "LinkedIn Share Statistics Error: #{e.message}"
    @cache[cache_key] = { data: {}, timestamp: Time.current }
    {}
  end

  # Get time-bound share statistics
  def get_time_bound_share_statistics(organization_urn, days_back = 30)
    cache_key = "time_share_stats_#{organization_urn}_#{days_back}"

    # Check cache first
    if @cache[cache_key] && @cache[cache_key][:timestamp] && (Time.current - @cache[cache_key][:timestamp]) < @cache_ttl
      return @cache[cache_key][:data]
    end

    end_time = Time.current
    start_time = end_time - days_back.days

    uri = URI("#{@base_url}/organizationalEntityShareStatistics")
    params = {
      q: 'organizationalEntity',
      organizationalEntity: organization_urn,
      'timeIntervals.timeGranularityType' => 'DAY',
      'timeIntervals.timeRange.start' => (start_time.to_f * 1000).to_i,
      'timeIntervals.timeRange.end' => (end_time.to_f * 1000).to_i
    }
    uri.query = URI.encode_www_form(params)

    response = make_request(uri)
    return [] if response.nil?

    data = JSON.parse(response.body)
    share_data = data['elements'] || []

    @cache[cache_key] = { data: share_data, timestamp: Time.current }
    share_data
  rescue => e
    Rails.logger.error "LinkedIn Time-bound Share Statistics Error: #{e.message}"
    @cache[cache_key] = { data: [], timestamp: Time.current }
    []
  end

  # Get social metadata for specific posts
  def get_social_metadata(entity_urns)
    return [] if entity_urns.empty?

    uri = URI("#{@base_url}/socialMetadata")
    params = { ids: "List(#{entity_urns.join(',')})" }
    uri.query = URI.encode_www_form(params)

    response = make_request(uri)
    return {} if response.nil?

    data = JSON.parse(response.body)
    data['results'] || {}
  rescue => e
    Rails.logger.error "LinkedIn Social Metadata Error: #{e.message}"
    {}
  end

  # Get social actions (likes, comments) for posts
  def get_social_actions(entity_urn)
    uri = URI("#{@base_url}/socialActions/#{CGI.escape(entity_urn)}")

    response = make_request(uri)
    return {} if response.nil?

    JSON.parse(response.body)
  rescue => e
    Rails.logger.error "LinkedIn Social Actions Error: #{e.message}"
    {}
  end

  # Get comments for a specific post
  def get_post_comments(entity_urn, limit = 50)
    uri = URI("#{@base_url}/socialActions/#{CGI.escape(entity_urn)}/comments")
    params = { count: limit }
    uri.query = URI.encode_www_form(params)

    response = make_request(uri)
    return [] if response.nil?

    data = JSON.parse(response.body)
    data['elements'] || []
  rescue => e
    Rails.logger.error "LinkedIn Comments Error: #{e.message}"
    []
  end

  # Get likes for a specific post
  def get_post_likes(entity_urn, limit = 50)
    uri = URI("#{@base_url}/socialActions/#{CGI.escape(entity_urn)}/likes")
    params = { count: limit }
    uri.query = URI.encode_www_form(params)

    response = make_request(uri)
    return [] if response.nil?

    data = JSON.parse(response.body)
    data['elements'] || []
  rescue => e
    Rails.logger.error "LinkedIn Likes Error: #{e.message}"
    []
  end

  # Get organization information
  def get_organization_info(organization_urn)
    cache_key = "org_info_#{organization_urn}"

    # Check cache first
    if @cache[cache_key] && @cache[cache_key][:timestamp] && (Time.current - @cache[cache_key][:timestamp]) < @cache_ttl
      return @cache[cache_key][:data]
    end

    # Extract organization ID from URN
    org_id = organization_urn.split(':').last

    uri = URI("#{@base_url}/organizations/#{org_id}")
    params = {
      projection: '(id,localizedName,localizedDescription,website,industry,logoV2,staffCount,followerCount)'
    }
    uri.query = URI.encode_www_form(params)

    response = make_request(uri)
    return {} if response.nil?

    org_data = JSON.parse(response.body)
    @cache[cache_key] = { data: org_data, timestamp: Time.current }
    org_data
  rescue => e
    Rails.logger.error "LinkedIn Organization Info Error: #{e.message}"
    @cache[cache_key] = { data: {}, timestamp: Time.current }
    {}
  end

  private

  # Make HTTP request with proper headers
  def make_request(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Bearer #{@access_token}"
    request['X-Restli-Protocol-Version'] = '2.0.0'
    request['LinkedIn-Version'] = '202409'

    response = http.request(request)

    if response.code != '200'
      Rails.logger.warn "LinkedIn API Error: #{response.code} - #{response.body}"
      return nil
    end

    response
  end

  # Format organization URN
  def format_organization_urn(organization_id)
    return organization_id if organization_id.start_with?('urn:li:organization:')
    "urn:li:organization:#{organization_id}"
  end

  # Safe execution wrapper
  def safe_execute
    yield
  rescue => e
    Rails.logger.warn "Safe execute failed: #{e.message}"
    nil
  end

  # Extract demographic data from follower statistics
  def extract_demographic_data(follower_stats, demographic_type)
    return [] unless follower_stats[demographic_type]

    follower_stats[demographic_type].map do |item|
      {
        category: extract_category_name(item, demographic_type),
        organic_followers: item.dig('followerCounts', 'organicFollowerCount') || 0,
        paid_followers: item.dig('followerCounts', 'paidFollowerCount') || 0,
        total_followers: (item.dig('followerCounts', 'organicFollowerCount') || 0) +
                        (item.dig('followerCounts', 'paidFollowerCount') || 0),
        percentage: 0 # Will be calculated based on total followers
      }
    end.sort_by { |item| -item[:total_followers] }
  end

  # Extract category name based on demographic type
  def extract_category_name(item, demographic_type)
    case demographic_type
    when 'followerCountsByIndustry'
      # Map industry URNs to readable names
      map_industry_urn(item['industry'])
    when 'followerCountsByFunction'
      # Map function URNs to readable names
      map_function_urn(item['function'])
    when 'followerCountsBySeniority'
      # Map seniority URNs to readable names
      map_seniority_urn(item['seniority'])
    when 'followerCountsByStaffCountRange'
      map_staff_count_range(item['staffCountRange'])
    when 'followerCountsByGeoCountry'
      # Map geo URNs to country names
      map_geo_urn(item['geo'])
    when 'followerCountsByGeo'
      # Map geo URNs to market area names
      map_geo_urn(item['geo'])
    when 'followerCountsByAssociationType'
      item['associationType']&.capitalize || 'Unknown'
    else
      'Unknown'
    end
  end

  # Map industry URN to readable name
  def map_industry_urn(industry_urn)
    return 'Unknown' unless industry_urn

    industry_mapping = {
      '1' => 'Defense & Space',
      '2' => 'Computer Hardware',
      '3' => 'Computer Software',
      '4' => 'Computer Networking',
      '5' => 'Internet',
      '6' => 'Semiconductors',
      '7' => 'Telecommunications',
      '8' => 'Law Practice',
      '9' => 'Legal Services',
      '10' => 'Management Consulting',
      '96' => 'Information Technology and Services'
      # Add more mappings as needed
    }

    industry_id = industry_urn.split(':').last
    industry_mapping[industry_id] || "Industry #{industry_id}"
  end

  # Map function URN to readable name
  def map_function_urn(function_urn)
    return 'Unknown' unless function_urn

    function_mapping = {
      '1' => 'Accounting',
      '2' => 'Administrative',
      '3' => 'Arts and Design',
      '4' => 'Business Development',
      '5' => 'Community & Social Services',
      '6' => 'Consulting',
      '7' => 'Education',
      '8' => 'Engineering',
      '9' => 'Entrepreneurship',
      '10' => 'Finance',
      '11' => 'Healthcare Services',
      '12' => 'Human Resources',
      '13' => 'Information Technology',
      '14' => 'Legal',
      '15' => 'Marketing',
      '16' => 'Media & Communications',
      '17' => 'Military & Protective Services',
      '18' => 'Operations',
      '19' => 'Product Management',
      '20' => 'Program & Project Management',
      '21' => 'Purchasing',
      '22' => 'Quality Assurance',
      '23' => 'Real Estate',
      '24' => 'Research',
      '25' => 'Sales',
      '26' => 'Support'
      # Add more mappings as needed
    }

    function_id = function_urn.split(':').last
    function_mapping[function_id] || "Function #{function_id}"
  end

  # Map seniority URN to readable name
  def map_seniority_urn(seniority_urn)
    return 'Unknown' unless seniority_urn

    seniority_mapping = {
      '1' => 'Unpaid',
      '2' => 'Training',
      '3' => 'Entry level',
      '4' => 'Associate',
      '5' => 'Mid-Senior level',
      '6' => 'Director',
      '7' => 'Executive',
      '8' => 'Senior',
      '9' => 'Manager',
      '10' => 'Owner'
    }

    seniority_id = seniority_urn.split(':').last
    seniority_mapping[seniority_id] || "Seniority #{seniority_id}"
  end

  # Map staff count range to readable name
  def map_staff_count_range(staff_count_range)
    case staff_count_range
    when 'SIZE_1'
      '1 employee'
    when 'SIZE_2_TO_10'
      '2-10 employees'
    when 'SIZE_11_TO_50'
      '11-50 employees'
    when 'SIZE_51_TO_200'
      '51-200 employees'
    when 'SIZE_201_TO_500'
      '201-500 employees'
    when 'SIZE_501_TO_1000'
      '501-1000 employees'
    when 'SIZE_1001_TO_5000'
      '1001-5000 employees'
    when 'SIZE_5001_TO_10000'
      '5001-10000 employees'
    when 'SIZE_10001_OR_MORE'
      '10001+ employees'
    else
      staff_count_range || 'Unknown'
    end
  end

  # Map geo URN to readable name (simplified)
  def map_geo_urn(geo_urn)
    return 'Unknown' unless geo_urn

    # This is a simplified mapping - in production, you'd want a more comprehensive mapping
    geo_mapping = {
      '102713980' => 'United States',
      '103644278' => 'India',
      '101165590' => 'United Kingdom',
      '105072130' => 'Canada',
      '101282230' => 'Germany',
      '105117694' => 'Australia',
      '102890719' => 'Brazil',
      '102454443' => 'France'
      # Add more mappings as needed
    }

    geo_id = geo_urn.split(':').last
    geo_mapping[geo_id] || "Location #{geo_id}"
  end

  # Analyze follower growth trends
  def analyze_follower_growth_trends(time_bound_data)
    return {} if time_bound_data.empty?

    growth_by_day = time_bound_data.map do |day_data|
      start_time = Time.at(day_data.dig('timeRange', 'start') / 1000.0)
      organic_gain = day_data.dig('followerGains', 'organicFollowerGain') || 0
      paid_gain = day_data.dig('followerGains', 'paidFollowerGain') || 0

      {
        date: start_time.strftime('%Y-%m-%d'),
        day_name: start_time.strftime('%A'),
        organic_followers_gained: organic_gain,
        paid_followers_gained: paid_gain,
        total_followers_gained: organic_gain + paid_gain
      }
    end

    {
      daily_growth: growth_by_day,
      total_organic_growth: growth_by_day.sum { |day| day[:organic_followers_gained] },
      total_paid_growth: growth_by_day.sum { |day| day[:paid_followers_gained] },
      average_daily_growth: growth_by_day.any? ? growth_by_day.sum { |day| day[:total_followers_gained] }.to_f / growth_by_day.length : 0,
      best_growth_day: growth_by_day.max_by { |day| day[:total_followers_gained] },
      growth_trend: calculate_growth_trend(growth_by_day)
    }
  end

  # Analyze engagement trends
  def analyze_engagement_trends(time_bound_data)
    return {} if time_bound_data.empty?

    engagement_by_day = time_bound_data.map do |day_data|
      start_time = Time.at(day_data.dig('timeRange', 'start') / 1000.0)
      stats = day_data['totalShareStatistics'] || {}

      {
        date: start_time.strftime('%Y-%m-%d'),
        day_name: start_time.strftime('%A'),
        impressions: stats['impressionCount'] || 0,
        unique_impressions: stats['uniqueImpressionsCount'] || 0,
        clicks: stats['clickCount'] || 0,
        likes: stats['likeCount'] || 0,
        comments: stats['commentCount'] || 0,
        shares: stats['shareCount'] || 0,
        engagement_rate: stats['engagement'] || 0
      }
    end

    {
      daily_engagement: engagement_by_day,
      total_impressions: engagement_by_day.sum { |day| day[:impressions] },
      total_clicks: engagement_by_day.sum { |day| day[:clicks] },
      total_engagement: engagement_by_day.sum { |day| day[:likes] + day[:comments] + day[:shares] },
      average_engagement_rate: engagement_by_day.any? ? engagement_by_day.sum { |day| day[:engagement_rate] }.to_f / engagement_by_day.length : 0,
      best_engagement_day: engagement_by_day.max_by { |day| day[:engagement_rate] },
      engagement_trend: calculate_engagement_trend(engagement_by_day)
    }
  end

  # Calculate click-through rate
  def calculate_ctr(share_stats)
    impressions = share_stats.dig('totalShareStatistics', 'impressionCount') || 0
    clicks = share_stats.dig('totalShareStatistics', 'clickCount') || 0

    return 0 if impressions == 0
    ((clicks.to_f / impressions) * 100).round(4)
  end

  # Calculate total posts (simplified)
  def calculate_total_posts(share_stats)
    # This is a simplified calculation - in reality, you'd need to call additional APIs
    # to get the actual post count
    share_stats.dig('totalShareStatistics', 'shareCount') || 0
  end

  # Analyze top content type
  def analyze_top_content_type(time_bound_data)
    # This would require additional data about content types
    # For now, return a placeholder
    'Unknown'
  end

  # Analyze best posting day
  def analyze_best_posting_day(time_bound_data)
    return 'Unknown' if time_bound_data.empty?

    day_performance = {}

    time_bound_data.each do |day_data|
      start_time = Time.at(day_data.dig('timeRange', 'start') / 1000.0)
      day_name = start_time.strftime('%A')
      engagement_rate = day_data.dig('totalShareStatistics', 'engagement') || 0

      day_performance[day_name] ||= []
      day_performance[day_name] << engagement_rate
    end

    # Calculate average engagement rate per day
    avg_performance = day_performance.transform_values do |rates|
      rates.sum.to_f / rates.length
    end

    avg_performance.max_by { |day, rate| rate }&.first || 'Unknown'
  end

  # Calculate follower growth rate
  def calculate_follower_growth_rate(time_bound_data)
    return 0 if time_bound_data.empty?

    total_growth = time_bound_data.sum do |day_data|
      organic_gain = day_data.dig('followerGains', 'organicFollowerGain') || 0
      paid_gain = day_data.dig('followerGains', 'paidFollowerGain') || 0
      organic_gain + paid_gain
    end

    # Return growth rate as percentage per day
    days = time_bound_data.length
    return 0 if days == 0

    (total_growth.to_f / days).round(2)
  end

  # Calculate growth trend
  def calculate_growth_trend(growth_data)
    return 'stable' if growth_data.length < 2

    recent_half = growth_data.last(growth_data.length / 2)
    earlier_half = growth_data.first(growth_data.length / 2)

    recent_avg = recent_half.sum { |day| day[:total_followers_gained] }.to_f / recent_half.length
    earlier_avg = earlier_half.sum { |day| day[:total_followers_gained] }.to_f / earlier_half.length

    if recent_avg > earlier_avg * 1.1
      'increasing'
    elsif recent_avg < earlier_avg * 0.9
      'decreasing'
    else
      'stable'
    end
  end

  # Calculate engagement trend
  def calculate_engagement_trend(engagement_data)
    return 'stable' if engagement_data.length < 2

    recent_half = engagement_data.last(engagement_data.length / 2)
    earlier_half = engagement_data.first(engagement_data.length / 2)

    recent_avg = recent_half.sum { |day| day[:engagement_rate] }.to_f / recent_half.length
    earlier_avg = earlier_half.sum { |day| day[:engagement_rate] }.to_f / earlier_half.length

    if recent_avg > earlier_avg * 1.1
      'improving'
    elsif recent_avg < earlier_avg * 0.9
      'declining'
    else
      'stable'
    end
  end

  # Default analytics structure
  def default_comprehensive_analytics
    {
      organization: {
        id: nil,
        urn: nil,
        name: nil,
        description: nil,
        website: nil,
        industry: nil,
        logo_url: nil,
        follower_count: 0,
        staff_count: 0
      },
      follower_analytics: {
        lifetime_demographics: {},
        time_bound_growth: [],
        demographics: {
          by_industry: [],
          by_function: [],
          by_seniority: [],
          by_company_size: [],
          by_geography: [],
          by_market_area: [],
          by_association: []
        },
        growth_trends: {}
      },
      share_analytics: {
        lifetime_performance: {},
        time_bound_performance: [],
        performance_summary: {
          total_impressions: 0,
          unique_impressions: 0,
          total_clicks: 0,
          total_likes: 0,
          total_comments: 0,
          total_shares: 0,
          engagement_rate: 0,
          click_through_rate: 0
        },
        engagement_trends: {}
      },
      summary: {
        total_followers: 0,
        total_posts: 0,
        avg_engagement_rate: 0,
        top_performing_content_type: 'Unknown',
        best_posting_day: 'Unknown',
        follower_growth_rate: 0
      },
      collected_at: Time.current.iso8601
    }
  end
end