# app/services/facebook_pages_service.rb
require 'http'  # Add this at the top of the file

class FacebookPagesService
  def initialize(auth_token)
    @auth_token = auth_token
  end

  def fetch_pages
    response = HTTP.get(
      "https://graph.facebook.com/v18.0/me/accounts?fields=id,name,access_token,category,category_list,tasks,picture.width(200).height(200)",
      params: { access_token: @auth_token }
    )
    data = JSON.parse(response.body)
    transform_response(data)
  end

  private

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
        page_type: "facebook", # or "ig_business" based on your needs
        social_id: page["id"],
        page_id: page["id"],
        picture_url: picture_url,
        access_token: page["access_token"],
        connected: true,
        user_profile: user_info,
        page_info: {
          id: page["id"],
          name: page["name"],
          category: page["category"],
          category_list: page["category_list"],
          tasks: page["tasks"],
          picture: page["picture"] # Include full picture object like LinkedIn response
        }
      }
    end
  end

  # Alternative method to fetch user profile with picture (if needed)
  def fetch_user_info(access_token)
    begin
      response = HTTP.get(
        "https://graph.facebook.com/v18.0/me?fields=id,name,email,picture.width(200).height(200)",
        params: { access_token: access_token }
      )
      user_data = JSON.parse(response.body)
      
      {
        sub: user_data["id"],
        name: user_data["name"],
        email: user_data["email"],
        picture: user_data["picture"] # This will have the same structure as LinkedIn
      }
    rescue => e
      Rails.logger.error "Error fetching user info: #{e.message}"
      {}
    end
  end
end


