class InstagramInfluencerDiscoveryService
  require 'net/http'
  require 'json'
  
  # AI Service Configuration
  GROQ_API_KEY = "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"
  OPENAI_API_KEY = ENV['OPENAI_API_KEY']
  
  # Influencer size mapping
  INFLUENCER_SIZES = {
    'nano' => { min: 0, max: 10_000 },
    'micro' => { min: 10_000, max: 100_000 },
    'macro' => { min: 100_000, max: 1_000_000 },
    'mega' => { min: 1_000_000, max: Float::INFINITY }
  }.freeze

  def initialize(filters:, limit: 20, sort_by: 'followers')
    @filters = filters
    @limit = [limit, 100].min # Cap at 100
    @sort_by = sort_by
    @timeout = 30
    @start_time = Time.current
  end

  def discover_influencers
    begin
      Rails.logger.info "Starting Instagram influencer discovery with filters: #{@filters}"
      
      # Build AI prompt from filters
      prompt = build_discovery_prompt
      
      # Try AI services in order of preference
      ai_response = try_groq_api(prompt) || try_openai_api(prompt)
      
      if ai_response.present?
        influencers = parse_ai_response(ai_response)
        influencers = apply_additional_filtering(influencers)
        influencers = sort_and_limit_results(influencers)
        
        search_time = (Time.current - @start_time).round(2)
        
        return {
          success: true,
          influencers: influencers,
          total_results: influencers.length,
          search_time: search_time,
          ai_provider: ai_response[:provider],
          query_complexity: calculate_query_complexity
        }
      else
        # Fallback to mock data if AI fails
        Rails.logger.warn "AI services failed, using mock data"
        influencers = generate_mock_influencers
        
        return {
          success: true,
          influencers: influencers,
          total_results: influencers.length,
          search_time: (Time.current - @start_time).round(2),
          ai_provider: 'mock_fallback',
          query_complexity: 'low'
        }
      end

    rescue StandardError => e
      Rails.logger.error "Instagram Influencer Discovery Service Error: #{e.message}"
      return {
        success: false,
        error: 'discovery_failed',
        message: "Failed to discover influencers: #{e.message}"
      }
    end
  end

  private

  def build_discovery_prompt
    prompt_parts = []
    
    # Base instruction
    prompt_parts << "Find Instagram influencers based on the following criteria and return them in JSON format."
    
    # Username search (highest priority)
    if @filters['username_search'].present?
      prompt_parts << "PRIORITY: Find influencers with username or name containing '#{@filters['username_search']}' (exact matches ranked highest)."
    end
    
    # Influencer filters
    if @filters['type'].present?
      prompt_parts << "Account type: #{@filters['type']}"
    end
    
    if @filters['size'].present?
      size_info = INFLUENCER_SIZES[@filters['size'].downcase]
      if size_info
        prompt_parts << "Follower count: #{size_info[:min].to_s.gsub(/\d(?=(\d{3})+$)/, '\&,')} to #{size_info[:max] == Float::INFINITY ? '∞' : size_info[:max].to_s.gsub(/\d(?=(\d{3})+$)/, '\&,')}"
      end
    end
    
    if @filters['gender'].present?
      prompt_parts << "Gender: #{@filters['gender']}"
    end
    
    if @filters['location'].present? || @filters['country'].present?
      location = @filters['location'] || @filters['country']
      prompt_parts << "Location/Country: #{location}"
    end
    
    if @filters['categories'].present? && @filters['categories'].is_a?(Array)
      prompt_parts << "Content categories: #{@filters['categories'].join(', ')}"
    end
    
    # Audience filters
    if @filters['audience_filters'].present?
      audience = @filters['audience_filters']
      
      if audience['age_range_min'].present? && audience['age_range_max'].present?
        prompt_parts << "Audience age: #{audience['age_range_min']}-#{audience['age_range_max']}"
      end
      
      if audience['gender'].present?
        prompt_parts << "Audience gender: #{audience['gender']}"
      end
      
      if audience['location'].present?
        prompt_parts << "Audience location: #{audience['location']}"
      end
      
      if audience['interests'].present? && audience['interests'].is_a?(Array)
        prompt_parts << "Audience interests: #{audience['interests'].join(', ')}"
      end
    end
    
    # Performance filters
    if @filters['performance_filters'].present?
      perf = @filters['performance_filters']
      
      if perf['engagement_rate_min'].present?
        prompt_parts << "Minimum engagement rate: #{perf['engagement_rate_min']}%"
      end
      
      if perf['avg_views_min'].present?
        prompt_parts << "Minimum average views: #{perf['avg_views_min']}"
      end
    end
    
    # Output format instruction
    prompt_parts << "Return exactly #{@limit} influencers in this JSON format:"
    prompt_parts << JSON.pretty_generate({
      "influencers": [
        {
          "username": "@example_user",
          "followers": 150000,
          "location": "India",
          "category": "Fashion",
          "engagement_rate": 4.2,
          "audience": {
            "age_range": "18-34",
            "gender": "Mixed",
            "location": "India",
            "interests": ["Fashion", "Beauty"],
            "quality_score": 85
          },
          "recent_posts": [
            "https://instagram.com/p/example1",
            "https://instagram.com/p/example2"
          ]
        }
      ]
    })
    
    # Sort instruction
    sort_instruction = case @sort_by
                      when 'engagement' then "Sort by engagement rate (highest first)"
                      when 'quality_score' then "Sort by audience quality score (highest first)"
                      when 'followers' then "Sort by follower count (highest first)"
                      else "Sort by follower count (highest first)"
                      end
    
    prompt_parts << sort_instruction
    
    return prompt_parts.join("\n\n")
  end

  def try_groq_api(prompt)
    return nil unless GROQ_API_KEY.present?
    
    begin
      Rails.logger.info "Trying Groq API for influencer discovery"
      
      uri = URI('https://api.groq.com/openai/v1/chat/completions')
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = @timeout
      
      request = Net::HTTP::Post.new(uri)
      request['Authorization'] = "Bearer #{GROQ_API_KEY}"
      request['Content-Type'] = 'application/json'
      request.body = {
        model: 'llama3-70b-8192',
        messages: [
          {
            role: 'system',
            content: 'You are an Instagram influencer discovery expert. Return only valid JSON responses with accurate influencer data.'
          },
          {
            role: 'user',
            content: prompt
          }
        ],
        temperature: 0.7,
        max_tokens: 4000
      }.to_json
      
      response = http.request(request)
      
      if response.code == '200'
        result = JSON.parse(response.body)
        content = result.dig('choices', 0, 'message', 'content')
        
        if content.present?
          Rails.logger.info "Groq API successful"
          return { content: content, provider: 'groq' }
        end
      else
        Rails.logger.warn "Groq API failed: #{response.code} - #{response.body}"
      end
      
    rescue StandardError => e
      Rails.logger.error "Groq API error: #{e.message}"
    end
    
    return nil
  end

  def try_openai_api(prompt)
    return nil unless OPENAI_API_KEY.present?
    
    begin
      Rails.logger.info "Trying OpenAI API for influencer discovery"
      
      uri = URI('https://api.openai.com/v1/chat/completions')
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = @timeout
      
      request = Net::HTTP::Post.new(uri)
      request['Authorization'] = "Bearer #{OPENAI_API_KEY}"
      request['Content-Type'] = 'application/json'
      request.body = {
        model: 'gpt-3.5-turbo',
        messages: [
          {
            role: 'system',
            content: 'You are an Instagram influencer discovery expert. Return only valid JSON responses with accurate influencer data.'
          },
          {
            role: 'user',
            content: prompt
          }
        ],
        temperature: 0.7,
        max_tokens: 3000
      }.to_json
      
      response = http.request(request)
      
      if response.code == '200'
        result = JSON.parse(response.body)
        content = result.dig('choices', 0, 'message', 'content')
        
        if content.present?
          Rails.logger.info "OpenAI API successful"
          return { content: content, provider: 'openai' }
        end
      else
        Rails.logger.warn "OpenAI API failed: #{response.code} - #{response.body}"
      end
      
    rescue StandardError => e
      Rails.logger.error "OpenAI API error: #{e.message}"
    end
    
    return nil
  end

  def parse_ai_response(ai_response)
    content = ai_response[:content]
    
    # Try to extract JSON from the response
    json_match = content.match(/\{.*\}/m)
    return [] unless json_match
    
    begin
      parsed = JSON.parse(json_match[0])
      influencers = parsed['influencers'] || []
      
      # Validate and clean the data
      influencers.map do |influencer|
        {
          username: influencer['username']&.to_s || '@unknown',
          followers: influencer['followers']&.to_i || 0,
          location: influencer['location']&.to_s || 'Unknown',
          category: influencer['category']&.to_s || 'General',
          engagement_rate: influencer['engagement_rate']&.to_f || 0.0,
          audience: {
            age_range: influencer.dig('audience', 'age_range') || '18-35',
            gender: influencer.dig('audience', 'gender') || 'Mixed',
            location: influencer.dig('audience', 'location') || 'Unknown',
            interests: influencer.dig('audience', 'interests') || [],
            quality_score: influencer.dig('audience', 'quality_score')&.to_i || 70
          },
          recent_posts: influencer['recent_posts'] || []
        }
      end
      
    rescue JSON::ParserError => e
      Rails.logger.error "Failed to parse AI response JSON: #{e.message}"
      return []
    end
  end

  def apply_additional_filtering(influencers)
    filtered = influencers
    
    # Apply username search priority
    if @filters['username_search'].present?
      search_term = @filters['username_search'].downcase
      
      # Separate exact matches and partial matches
      exact_matches = filtered.select { |inf| inf[:username].downcase.include?(search_term) }
      other_matches = filtered.reject { |inf| inf[:username].downcase.include?(search_term) }
      
      # Prioritize exact matches
      filtered = exact_matches + other_matches
    end
    
    # Apply performance filters
    if @filters['performance_filters'].present?
      perf = @filters['performance_filters']
      
      if perf['engagement_rate_min'].present?
        min_engagement = perf['engagement_rate_min'].to_f
        filtered = filtered.select { |inf| inf[:engagement_rate] >= min_engagement }
      end
      
      if perf['avg_views_min'].present?
        # This would need actual view data, for now we'll simulate
        min_views = perf['avg_views_min'].to_i
        filtered = filtered.select { |inf| inf[:followers] * 0.1 >= min_views }
      end
    end
    
    # Apply audience quality filter
    if @filters.dig('audience_filters', 'quality_score_min').present?
      min_quality = @filters.dig('audience_filters', 'quality_score_min').to_i
      filtered = filtered.select { |inf| inf.dig(:audience, :quality_score) >= min_quality }
    end
    
    return filtered
  end

  def sort_and_limit_results(influencers)
    # Sort based on the specified criteria
    sorted = case @sort_by
             when 'engagement'
               influencers.sort_by { |inf| -inf[:engagement_rate] }
             when 'quality_score'
               influencers.sort_by { |inf| -inf.dig(:audience, :quality_score) }
             when 'followers'
               influencers.sort_by { |inf| -inf[:followers] }
             else
               influencers.sort_by { |inf| -inf[:followers] }
             end
    
    # Limit results
    sorted.first(@limit)
  end

  def calculate_query_complexity
    complexity_score = 0
    
    complexity_score += 1 if @filters['username_search'].present?
    complexity_score += 1 if @filters['type'].present?
    complexity_score += 1 if @filters['size'].present?
    complexity_score += 1 if @filters['gender'].present?
    complexity_score += 1 if @filters['location'].present? || @filters['country'].present?
    complexity_score += (@filters['categories']&.length || 0)
    complexity_score += (@filters['audience_filters']&.keys&.length || 0)
    complexity_score += (@filters['performance_filters']&.keys&.length || 0)
    
    case complexity_score
    when 0..2 then 'low'
    when 3..5 then 'medium'
    else 'high'
    end
  end

  def generate_mock_influencers
    # Mock data for fallback when AI services fail
    mock_data = [
      {
        username: "@virat.kohli",
        followers: 265_000_000,
        location: "India",
        category: "Sports",
        engagement_rate: 2.8,
        audience: {
          age_range: "18-34",
          gender: "Mixed",
          location: "India",
          interests: ["Cricket", "Fitness"],
          quality_score: 91
        },
        recent_posts: [
          "https://instagram.com/p/virat_post1",
          "https://instagram.com/p/virat_post2"
        ]
      },
      {
        username: "@priyankachopra",
        followers: 91_000_000,
        location: "USA",
        category: "Entertainment",
        engagement_rate: 3.2,
        audience: {
          age_range: "18-35",
          gender: "Female",
          location: "Global",
          interests: ["Movies", "Fashion"],
          quality_score: 88
        },
        recent_posts: [
          "https://instagram.com/p/priyanka_post1"
        ]
      },
      {
        username: "@deepikapadukone",
        followers: 79_000_000,
        location: "India",
        category: "Entertainment",
        engagement_rate: 4.1,
        audience: {
          age_range: "18-35",
          gender: "Mixed",
          location: "India",
          interests: ["Movies", "Fashion", "Beauty"],
          quality_score: 89
        },
        recent_posts: [
          "https://instagram.com/p/deepika_post1",
          "https://instagram.com/p/deepika_post2"
        ]
      }
    ]
    
    # Filter mock data based on username search if provided
    if @filters['username_search'].present?
      search_term = @filters['username_search'].downcase
      mock_data = mock_data.select do |influencer|
        influencer[:username].downcase.include?(search_term) ||
        influencer[:category].downcase.include?(search_term)
      end
    end
    
    # Apply other filters to mock data
    mock_data = apply_additional_filtering(mock_data)
    
    # Sort and limit
    sort_and_limit_results(mock_data)
  end
end