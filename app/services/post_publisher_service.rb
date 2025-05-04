class PostPublisherService
  class FacebookError < StandardError; end
  class TokenExpiredError < FacebookError; end
  class InstagramAccountError < FacebookError; end

  def initialize(post)
    @post = post
    @page = post.social_page
    @logger = Rails.logger
  end

  def publish
    service = LinkedinShareService.new(
      access_token: @page.access_token,
      person_urn: "urn:li:person:#{@page.social_id}"
    )

    service.post_image(
      content: @post.comments,
      image_path: @post.s3_url,
      title: "Great Moment",
      description: @post.comments
    )

    success_message = "Published"
    @post.update(status: 'published', publish_log: success_message)

  rescue TokenExpiredError => e
    handle_error("Facebook access token has expired. Please reconnect your Facebook account.", e)
  rescue InstagramAccountError => e
    handle_error("Instagram business account not found. Please check your Facebook page connection.", e)
  rescue StandardError => e
    handle_error("Failed to publish post", e)
  end

  private

  def handle_error(message, error)
    error_message = "#{message}. Error: #{error.message}"
    @logger.error(error_message)
    @logger.error(error.backtrace.join("\n"))
    @post.update(status: 'failed', publish_log: error_message)
    raise error
  end

  def fetch_instagram_account_id
    @logger.info("Fetching Instagram account ID for page ID: #{@page.page_id}")

    response = HTTP.get(
      "https://graph.facebook.com/v18.0/#{@page.page_id}",
      params: {
        fields: "instagram_business_account",
        access_token: @page.access_token
      }
    )

    data = JSON.parse(response.body)
    handle_facebook_error(data["error"]) if data["error"]

    instagram_account = data["instagram_business_account"]
    raise InstagramAccountError, "No Instagram business account found for this Facebook page" if instagram_account.nil?

    instagram_id = instagram_account["id"]
    @logger.info("Successfully retrieved Instagram ID: #{instagram_id}")
    instagram_id
  end

  def handle_facebook_error(error)
    case error["code"]
    when 190
      if error["error_subcode"] == 463
        raise TokenExpiredError, "Facebook access token has expired"
      else
        raise FacebookError, "Invalid Facebook access token"
      end
    else
      raise FacebookError, error["message"]
    end
  end

  def create_media(instagram_id)
    @logger.info("Creating media for Instagram ID: #{instagram_id}")

    response = HTTP.post(
      "https://graph.facebook.com/v18.0/#{instagram_id}/media",
      params: {
        access_token: @page.access_token,
        image_url: @post.s3_url,
        caption: generate_caption
      }
    )

    data = JSON.parse(response.body)
    handle_facebook_error(data["error"]) if data["error"]

    creation_id = data["id"]
    @logger.info("Successfully created media with creation ID: #{creation_id}")
    creation_id
  end

  def publish_media(instagram_id, creation_id)
    @logger.info("Publishing media. Instagram ID: #{instagram_id}, Creation ID: #{creation_id}")

    response = HTTP.post(
      "https://graph.facebook.com/v18.0/#{instagram_id}/media_publish",
      params: {
        access_token: @page.access_token,
        creation_id: creation_id
      }
    )

    data = JSON.parse(response.body)
    handle_facebook_error(data["error"]) if data["error"]

    @logger.info("Successfully published media to Instagram")
  end

  def generate_caption
    [@post.note, @post.comments, @post.hashtags].compact.join("\n\n")
  end
end
