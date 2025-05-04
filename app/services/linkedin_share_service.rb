# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'
require 'open-uri'
require 'tempfile'

class LinkedinShareService
  LINKEDIN_API_BASE = 'https://api.linkedin.com/v2'
  RESTLI_HEADER = { 'X-Restli-Protocol-Version' => '2.0.0' }.freeze

  def initialize(access_token:, person_urn:)
    @access_token = access_token
    @person_urn = person_urn
  end

  def post_text(content)
    body = base_post_body(content, 'NONE')
    post_to_linkedin("#{LINKEDIN_API_BASE}/ugcPosts", body)
  end

  def post_article(content:, title:, description:, url:)
    body = base_post_body(content, 'ARTICLE')
    body[:specificContent]['com.linkedin.ugc.ShareContent'][:media] = [
      {
        status: 'READY',
        description: { text: description },
        originalUrl: url,
        title: { text: title }
      }
    ]
    post_to_linkedin("#{LINKEDIN_API_BASE}/ugcPosts", body)
  end

  def post_image(content:, image_path:, title:, description:)
    upload_info = register_upload('feedshare-image')
    raise "LinkedIn did not return valid upload data: #{upload_info.inspect}" unless upload_info[:upload_url] && upload_info[:asset]

    upload_remote_image(upload_info[:upload_url], image_path)

    body = base_post_body(content, 'IMAGE')
    body[:specificContent]['com.linkedin.ugc.ShareContent'][:media] = [
      {
        status: 'READY',
        description: { text: description },
        media: upload_info[:asset],
        title: { text: title }
      }
    ]
    post_to_linkedin("#{LINKEDIN_API_BASE}/ugcPosts", body)
  end

  private

  def base_post_body(content, media_category)
    {
      author: @person_urn,
      lifecycleState: 'PUBLISHED',
      specificContent: {
        'com.linkedin.ugc.ShareContent' => {
          shareCommentary: {
            text: content
          },
          shareMediaCategory: media_category
        }
      },
      visibility: {
        'com.linkedin.ugc.MemberNetworkVisibility' => 'PUBLIC'
      }
    }
  end

  def post_to_linkedin(url, body)
    uri = URI.parse(url)
    request = Net::HTTP::Post.new(uri, headers)
    request.body = body.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    if response.code.to_i.between?(200, 299)
      puts "✅ LinkedIn share created successfully"
      JSON.parse(response.body) rescue { success: true, response_code: response.code }
    else
      puts "❌ LinkedIn API error: #{response.code}"
      puts "Response body: #{response.body}" # Debug: get LinkedIn's error message
      { success: false, error: response.body, response_code: response.code }
    end
  end

  def headers
    {
      'Authorization' => "Bearer #{@access_token}",
      'Content-Type' => 'application/json'
    }.merge(RESTLI_HEADER)
  end

  def register_upload(recipe_type)
    uri = URI.parse("#{LINKEDIN_API_BASE}/assets?action=registerUpload")
    request = Net::HTTP::Post.new(uri, headers)

    request.body = {
      registerUploadRequest: {
        recipes: ["urn:li:digitalmediaRecipe:#{recipe_type}"],
        owner: @person_urn,
        serviceRelationships: [
          {
            relationshipType: 'OWNER',
            identifier: 'urn:li:userGeneratedContent'
          }
        ]
      }
    }.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(request) }

    if response.code.to_i.between?(200, 299)
      parsed = JSON.parse(response.body)
      {
        upload_url: parsed.dig('value', 'uploadMechanism', 'com.linkedin.digitalmedia.uploading.MediaUploadHttpRequest', 'uploadUrl'),
        asset: parsed.dig('value', 'asset')
      }
    else
      puts "❌ LinkedIn register upload error: #{response.code}"
      puts "Body: #{response.body}"
      {}
    end
  rescue => e
    puts "❌ Failed to register upload: #{e.message}"
    {}
  end

  def upload_remote_image(upload_url, image_path)
    raise "Upload URL is nil" unless upload_url

    puts "Processing image upload for: #{image_path}"

    image_data = URI.open(image_path, 'rb') { |file| file.read }

    uri = URI.parse(upload_url)
    request = Net::HTTP::Put.new(uri)
    request.body = image_data
    request['Content-Type'] = 'application/octet-stream'

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
      http.request(request)
    end

    if response.code.to_i.between?(200, 299)
      puts "✅ Image uploaded successfully to LinkedIn"
    else
      puts "❌ Image upload failed: #{response.code}"
      puts "Response: #{response.body}"
    end
  rescue => e
    puts "❌ Exception during image upload: #{e.message}"
  end
end
