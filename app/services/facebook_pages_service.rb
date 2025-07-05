# app/services/facebook_pages_service.rb
require 'http'
require 'net/http'
require 'uri'
require 'json'

class FacebookPagesService
  FACEBOOK_APP_ID = '499798672825129'
  FACEBOOK_APP_SECRET = '0972b471f1d251f8db7762be1db4613c'

  def initialize(auth_token)
    @auth_token = auth_token
  end

  def fetch_pages
    # First try to get Facebook pages
    response = HTTP.get(
      "https://graph.facebook.com/v18.0/me/accounts?fields=id,name,access_token,category,category_list,tasks,picture.width(50).height(50)",
      params: { access_token: @auth_token }
    )
    data = JSON.parse(response.body)
    
    # If no Facebook pages found, try Instagram
    if data["data"].nil? || data["data"].empty?
      instagram_data = fetch_instagram_profile
      return instagram_data if instagram_data
    end
    
    transform_response(data)
  end

  private

  def fetch_instagram_profile
    # Debug the access token to check for Instagram permissions
    token_info = debug_access_token
    return nil unless token_info && token_info["data"]["is_valid"]

    # Check if target_ids exist in granular_scopes
    granular_scopes = token_info["data"]["granular_scopes"]
    instagram_scope = granular_scopes&.find { |scope| scope["scope"] == "instagram_basic" }
    
    if instagram_scope.nil? || instagram_scope["target_ids"].nil?
      Rails.logger.info "There is no active pages found"
      return []
    end

    # Get Instagram user ID from target_ids
    instagram_user_id = instagram_scope["target_ids"].first
    
    # Fetch Instagram profile data
    instagram_profile = fetch_instagram_user_data(instagram_user_id)
    
    if instagram_profile
      [transform_instagram_response(instagram_profile)]
    else
      []
    end
  end

  def debug_access_token
    uri = URI("https://graph.facebook.com/v18.0/debug_token")
    
    params = {
      input_token: @auth_token,
      access_token: "#{FACEBOOK_APP_ID}|#{FACEBOOK_APP_SECRET}"
    }
    
    uri.query = URI.encode_www_form(params)
    
    response = Net::HTTP.get_response(uri)
    
    if response.code == "200"
      JSON.parse(response.body)
    else
      Rails.logger.error "Failed to debug token: #{response.body}"
      nil
    end
  end

  def fetch_instagram_user_data(instagram_user_id)
    uri = URI("https://graph.facebook.com/v18.0/#{instagram_user_id}")
    
    params = {
      access_token: @auth_token,
      fields: "id,username,media_count,media,biography,followers_count,profile_picture_url"
    }
    
    uri.query = URI.encode_www_form(params)
    
    response = Net::HTTP.get_response(uri)
    
    Rails.logger.info "=== INSTAGRAM BASIC PROFILE ==="
    Rails.logger.info "Status: #{response.code}"
    Rails.logger.info "Response: #{response.body}"
    
    if response.code == "200"
      JSON.parse(response.body)
    else
      Rails.logger.error "Failed to fetch Instagram profile: #{response.body}"
      nil
    end
  end

  def transform_instagram_response(instagram_data)
    {
      name: instagram_data["username"],
      username: instagram_data["username"],
      page_type: "instagram",
      type: "ig_business",
      social_id: instagram_data["id"],
      page_id: instagram_data["id"],
      picture_url: instagram_data["profile_picture_url"],
      access_token: @auth_token,
      connected: false,
      user_profile: {
        sub: instagram_data["id"],
        name: instagram_data["username"],
        email: nil, # Instagram doesn't provide email
        picture: {
          data: {
            url: instagram_data["profile_picture_url"]
          }
        }
      },
      page_info: {
        id: instagram_data["id"],
        name: instagram_data["username"],
        biography: instagram_data["biography"],
        followers_count: instagram_data["followers_count"],
        media_count: instagram_data["media_count"],
        media: instagram_data["media"],
        profile_picture_url: instagram_data["profile_picture_url"]
      }
    }
  end

  def transform_response(data)
    data["data"].map do |page|
      # Extract picture data
      picture_data = page["picture"]&.dig("data")
      picture_url = picture_data&.dig("url")

      # Get user info using page access token
      user_info = fetch_user_info(page["access_token"])

      {
        name: page["name"],
        username: page["name"].parameterize,
        page_type: "facebook",
        type: "ig_business",
        social_id: page["id"],
        page_id: page["id"],
        picture_url: picture_url,
        access_token: page["access_token"],
        connected: false,
        user_profile: user_info,
        page_info: {
          id: page["id"],
          name: page["name"],
          category: page["category"],
          category_list: page["category_list"],
          tasks: page["tasks"],
          picture: page["picture"]
        }
      }
    end
  end

  def fetch_user_info(access_token)
    begin
      response = HTTP.get(
        "https://graph.facebook.com/v18.0/me?fields=id,name,email,picture.width(50).height(50)",
        params: { access_token: access_token }
      )
      user_data = JSON.parse(response.body)

      {
        sub: user_data["id"],
        name: user_data["name"],
        email: user_data["email"],
        picture: user_data["picture"]
      }
    rescue => e
      Rails.logger.error "Error fetching user info: #{e.message}"
      {}
    end
  end
end