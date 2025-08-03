class ContentAiService
  require 'net/http'
  require 'json'
  
  # Configuration for different AI services
  GROQ_API_KEY = "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"
  ANTHROPIC_API_KEY = ENV['ANTHROPIC_API_KEY']
  
  def initialize(description)
    @description = description
    @timeout = 30
  end

  def generate
    Rails.logger.info "Content AI generation started for: #{@description}"
    
    # Try different AI services in order of preference
    ai_response = try_groq_api || try_anthropic_api
    if ai_response.present?
      Rails.logger.info "Content AI generation successful: #{ai_response.length} chars"
      return ai_response
    else
      Rails.logger.warn "Content AI generation failed, using template"
      return generate_with_template
    end
  end

  private

  def try_groq_api
    return nil unless GROQ_API_KEY.present?
    
    begin
      Rails.logger.info "Trying Groq API for content generation"
      
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
            content: 'You are a professional social media content creator and digital marketing expert. Create engaging, authentic, and platform-appropriate content based on the user\'s description. Include relevant hashtags, emojis, and call-to-action when appropriate. Keep the tone conversational and engaging.'
          },
          {
            role: 'user',
            content: build_content_prompt(@description)
          }
        ],
        max_tokens: 1000,
        temperature: 0.8
      }.to_json
      
      response = http.request(request)
      if response.code == '200'
        result = JSON.parse(response.body)
        if result.dig('choices', 0, 'message', 'content')
          return result['choices'][0]['message']['content'].strip
        end
      else
        Rails.logger.error "Groq API error: #{response.code} - #{response.body}"
      end
      
      return nil
    rescue => e
      Rails.logger.error "Groq API call failed: #{e.message}"
      return nil
    end
  end

  def try_anthropic_api
    return nil unless ANTHROPIC_API_KEY.present?
    
    begin
      Rails.logger.info "Trying Anthropic API for content generation"
      
      uri = URI('https://api.anthropic.com/v1/messages')
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = @timeout
      
      request = Net::HTTP::Post.new(uri)
      request['x-api-key'] = ANTHROPIC_API_KEY
      request['Content-Type'] = 'application/json'
      request['anthropic-version'] = '2023-06-01'
      
      request.body = {
        model: 'claude-3-sonnet-20240229',
        max_tokens: 1000,
        messages: [
          {
            role: 'user',
            content: build_content_prompt(@description)
          }
        ]
      }.to_json
      
      response = http.request(request)
      
      if response.code == '200'
        result = JSON.parse(response.body)
        if result.dig('content', 0, 'text')
          return result['content'][0]['text'].strip
        end
      else
        Rails.logger.error "Anthropic API error: #{response.code} - #{response.body}"
      end
      
      return nil
    rescue => e
      Rails.logger.error "Anthropic API call failed: #{e.message}"
      return nil
    end
  end

  def build_content_prompt(description)
    "Create engaging social media content based on this description: #{description}
    
    Please generate content that:
    - Is engaging and authentic
    - Includes relevant hashtags (3-5 hashtags)
    - Uses appropriate emojis to enhance the message
    - Has a clear call-to-action when relevant
    - Is suitable for multiple social media platforms
    - Maintains a conversational and professional tone
    - Is optimized for engagement and reach
    
    Make the content ready to post immediately."
  end

  def generate_with_template
    Rails.logger.info "Generating content with template"
    
    content_type = determine_content_type(@description)
    
    case content_type
    when 'promotional'
      generate_promotional_content
    when 'educational'
      generate_educational_content
    when 'engagement'
      generate_engagement_content
    when 'announcement'
      generate_announcement_content
    else
      generate_general_content
    end
  end

  def determine_content_type(description)
    desc_lower = description.downcase
    
    return 'promotional' if desc_lower.include?('promote') || desc_lower.include?('sale') || desc_lower.include?('offer')
    return 'educational' if desc_lower.include?('tip') || desc_lower.include?('how to') || desc_lower.include?('learn')
    return 'engagement' if desc_lower.include?('question') || desc_lower.include?('poll') || desc_lower.include?('engage')
    return 'announcement' if desc_lower.include?('announce') || desc_lower.include?('news') || desc_lower.include?('update')
    
    'general'
  end

  def generate_promotional_content
    "🚀 Exciting news! #{@description}
    
Don't miss out on this amazing opportunity! 
    
✨ Why choose us?
• Quality you can trust
• Exceptional customer service
• Competitive pricing
    
Ready to get started? Click the link in our bio or DM us for more info! 💬
    
#Marketing #Business #Quality #CustomerFirst #ExcitingNews"
  end

  def generate_educational_content
    "💡 Pro Tip: #{@description}
    
Here's what you need to know:
    
📚 Key takeaways:
• Stay informed and updated
• Apply these insights to your strategy
• Share your experience with others
    
What's your experience with this? Let us know in the comments! 👇
    
#Education #ProTips #Learning #Growth #Knowledge"
  end

  def generate_engagement_content
    "🤔 Let's talk about: #{@description}
    
We want to hear from YOU! 
    
💭 Your thoughts matter:
• What's your perspective?
• Have you experienced this?
• What would you add?
    
Drop a comment below and let's start a conversation! 👇
    
#Community #Engagement #Discussion #YourVoice #LetsTalk"
  end

  def generate_announcement_content
    "📢 Important Update: #{@description}
    
We're excited to share this news with our community!
    
🎉 What this means for you:
• Stay tuned for more updates
• Follow us for the latest news
• Share this with friends who might be interested
    
Thank you for being part of our journey! 🙏
    
#Announcement #Update #Community #ExcitingNews #StayTuned"
  end

  def generate_general_content
    "✨ #{@description}
    
We believe in sharing valuable content with our community!
    
🌟 Here's what we want you to know:
• Every post is crafted with care
• Your engagement means the world to us
• We're here to provide value and inspiration
    
What would you like to see more of? Let us know! 💬
    
#SocialMedia #Content #Community #Engagement #ValueFirst"
  end
end