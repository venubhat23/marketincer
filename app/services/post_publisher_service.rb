class PostPublisherService
  class FacebookError < StandardError; end
  class TokenExpiredError < FacebookError; end
  class InstagramAccountError < FacebookError; end

  def initialize(post)
    @post = post
    @page = post.social_page
    @logger = Rails.logger
  end

  #test
  def publish
    if @page.page_type == "linkedin"
      if @page.is_page == true
       person_urn = "urn:li:company:#{@page.social_id}"
      else
        person_urn = "urn:li:person:#{@page.social_id}"
      end
      service = LinkedinShareService.new(
        access_token: @page.access_token,
        person_urn: person_urn
      )
      service.post_image(
        content: @post.comments,
        image_path: @post.s3_url,
        title: "Great Moment",
        description: @post.comments
      )

      success_message = "Published"
      @post.update(status: 'published', publish_log: success_message)
    else
      Rails.logger.info("Starting publication process for post ID: #{@post.id}")

      instagram_account_id = fetch_instagram_account_id
      Rails.logger.info("Step 1: Retrieved Instagram Account ID: #{instagram_account_id}")

      creation_id = create_media(instagram_account_id)
      Rails.logger.info("Step 2: Created Media with Creation ID: #{creation_id}")

      publish_media(instagram_account_id, creation_id)
      Rails.logger.info("Step 3: Successfully published media. Instagram Account ID: #{instagram_account_id}, Creation ID: #{creation_id}")

      success_message = "✓ Post successfully published to Instagram!\n" \
                        "Step 1: Retrieved Instagram Account ID: #{instagram_account_id}\n" \
                        "Step 2: Created Media with Creation ID: #{creation_id}\n" \
                        "Step 3: Published to Instagram Account: #{instagram_account_id}"

      @post.update(status: 'published', publish_log: success_message)
    end
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
    Rails.logger.error(error_message)
    Rails.logger.error(error.backtrace.join("\n"))
    @post.update(status: 'failed', publish_log: error_message)
    raise error
  end

  def fetch_instagram_account_id
    Rails.logger.info("Fetching Instagram account ID for page ID: #{@page.page_id}")
    response = HTTP.get(
      "https://graph.facebook.com/v18.0/#{@page.page_id}",
      params: {
        fields: "instagram_business_account",
        access_token: @page.access_token
      }
    )

    data = JSON.parse(response.body)

    if data["error"]
      handle_facebook_error(data["error"])
    end

    instagram_account = data["instagram_business_account"]
    if instagram_account.nil?
      raise InstagramAccountError, "No Instagram business account found for this Facebook page"
    end

    instagram_id = instagram_account["id"]
    Rails.logger.info("Successfully retrieved Instagram ID: #{instagram_id}")
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
    Rails.logger.info("Creating media for Instagram ID: #{instagram_id}")
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
    Rails.logger.info("Successfully created media with creation ID: #{creation_id}")
    creation_id
  end

  def publish_media(instagram_id, creation_id)
    Rails.logger.info("Publishing media. Instagram ID: #{instagram_id}, Creation ID: #{creation_id}")
    response = HTTP.post(
      "https://graph.facebook.com/v18.0/#{instagram_id}/media_publish",
      params: {
        access_token: @page.access_token,
        creation_id: creation_id
      }
    )

    data = JSON.parse(response.body)
    handle_facebook_error(data["error"]) if data["error"]

    Rails.logger.info("Successfully published media to Instagram")
  end

  def generate_caption
    [@post.note, @post.comments, @post.hashtags].compact.join("\n\n")
  end
end
