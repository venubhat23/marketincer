class PostPublisherService
  def initialize(post)
    @post = post
    @page = post.social_page
  end

  def publish
    return unless @page.page_type == 'ig_business'
    
    instagram_account_id = fetch_instagram_account_id
    creation_id = create_media(instagram_account_id)
    publish_media(instagram_account_id, creation_id)
  end

  private

  def fetch_instagram_account_id
    response = HTTP.get(
      "https://graph.facebook.com/v18.0/#{@page.page_id}",
      params: {
        fields: "instagram_business_account",
        access_token: @page.access_token
      }
    )
    
    data = JSON.parse(response.body)
    data.dig("instagram_business_account", "id")
  end

  def create_media(instagram_id)
    response = HTTP.post(
      "https://graph.facebook.com/v18.0/#{instagram_id}/media",
      params: {
        access_token: @page.access_token,
        image_url: @post.s3_url,
        caption: generate_caption
      }
    )
    
    data = JSON.parse(response.body)
    data["id"]
  end

  def publish_media(instagram_id, creation_id)
    response = HTTP.post(
      "https://graph.facebook.com/v18.0/#{instagram_id}/media_publish",
      params: {
        access_token: @page.access_token,
        creation_id: creation_id
      }
    )
    
    @post.update(status: 'published')
  end

  def generate_caption
    [@post.note, @post.comments, @post.hashtags].compact.join("\n\n")
  end
end