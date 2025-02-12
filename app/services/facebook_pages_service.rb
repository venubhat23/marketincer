# app/services/facebook_pages_service.rb
require 'http'  # Add this at the top of the file

class FacebookPagesService
  def initialize(auth_token)
    @auth_token = auth_token
  end

  def fetch_pages
    response = HTTP.get(
      "https://graph.facebook.com/v18.0/me/accounts",
      params: { access_token: @auth_token }
    )
    data = JSON.parse(response.body)
    transform_response(data)
  end

  private

  def transform_response(data)
    data["data"].map do |page|
      {
        name: page["name"],
        username: page["name"].parameterize,
        type: "ig_business",
        social_id: page["id"],
        page_id: page["id"],
        access_token: page["access_token"],
        user: fetch_user_info(page["access_token"])
      }
    end
  end

  def fetch_user_info(access_token)
    response = HTTP.get(
      "https://graph.facebook.com/v18.0/me",
      params: {
        access_token: access_token,
        fields: "id,name,picture"
      }
    )
    JSON.parse(response.body)
  end
end


