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
    # Step 1: Register the upload with LinkedIn
    upload_info = register_upload('feedshare-image')

    unless upload_info[:upload_url] && upload_info[:asset]
      raise "LinkedIn did not return a valid upload URL or asset: #{upload_info.inspect}"
    end

    # Step 2: Download the image from S3 and upload it to LinkedIn
    upload_remote_image(upload_info[:upload_url], image_path)

    # Step 3: Create the share with the uploaded image
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
      puts "LinkedIn share created successfully"
      begin
        JSON.parse(response.body)
      rescue => e
        puts "Warning: Could not parse JSON response: #{e.message}"
        { success: true, response_code: response.code }
      end
    else
      puts "LinkedIn API error: #{response.code}"
      # Avoid printing potentially binary response body
      { success: false, error: "API Error", response_code: response.code }
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
      puts "LinkedIn register upload error: #{response.code}"
      {}
    end
  rescue => e
    puts "Failed to register upload: #{e.message}"
    {}
  end

  # def upload_remote_image(upload_url, image_path)
  #   raise "Upload URL is nil" unless upload_url
    
  #   # Only log the path, not any binary data
  #   puts "Processing image upload for: #{image_path}"
    
  #   begin
  #     # Use Net::HTTP directly to download the binary file
  #     image_uri = URI.parse(image_path)
  #     binary_data = nil
      
  #     Net::HTTP.start(image_uri.host, image_uri.port, use_ssl: image_uri.scheme == 'https') do |http|
  #       response = http.get(image_uri.request_uri)
  #       if response.code.to_i.between?(200, 299)
  #         binary_data = response.body
  #         puts "Successfully downloaded image (#{binary_data.bytesize} bytes)"
  #       else
  #         raise "Failed to download image: #{response.code}"
  #       end
  #     end
      
  #     # Upload the binary data to LinkedIn
  #     uri = URI.parse(upload_url)
      
  #     # LinkedIn expects binary data in the request
  #     request = Net::HTTP::Post.new(uri)
      
  #     # Don't add Content-Type for binary upload
  #     request.body = binary_data
      
  #     response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
  #       http.request(request)
  #     end
      
  #     if response.code.to_i.between?(200, 299)
  #       puts "Image uploaded successfully to LinkedIn"
  #       true
  #     else
  #       # Don't try to print the potentially binary response body
  #       puts "LinkedIn image upload error: #{response.code}"
  #       raise "Failed to upload image to LinkedIn: #{response.code}"
  #     end
  #   rescue => e
  #     # Just print the error message, not the backtrace which might contain binary data
  #     puts "Error uploading image: #{e.message}"
  #     raise e
  #   end
  # end
def upload_remote_image(upload_url, image_path)
  raise "Upload URL is nil" unless upload_url
  
  # Only log the path, not any binary data
  puts "Processing image upload for: #{image_path}"
  
  begin
    # Use Net::HTTP directly to download the binary file
    image_uri = URI.parse(image_path)
    binary_data = nil
    
    Net::HTTP.start(image_uri.host, image_uri.port, use_ssl: image_uri.scheme == 'https') do |http|
      response = http.get(image_uri.request_uri)
      if response.code.to_i.between?(200, 299)
        binary_data = response.body
        puts "Successfully downloaded image (#{binary_data.bytesize} bytes)"
      else
        raise "Failed to download image: #{response.code}"
      end
    end
    
    # Upload the binary data to LinkedIn
    uri = URI.parse(upload_url)
    
    # LinkedIn expects binary data with Content-Type header for image uploads
    request = Net::HTTP::Put.new(uri) # Changed from POST to PUT
    request['Content-Type'] = 'application/octet-stream' # Added Content-Type header
    request.body = binary_data
    
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end
    
    if response.code.to_i.between?(200, 299)
      puts "Image uploaded successfully to LinkedIn"
      true
    else
      puts "LinkedIn image upload error: #{response.code}"
      puts "Error response: #{response.body}" # Added to see more error details
      raise "Failed to upload image to LinkedIn: #{response.code}"
    end
  rescue => e
    puts "Error uploading image: #{e.message}"
    raise e
  end
end
end