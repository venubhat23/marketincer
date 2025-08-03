#!/usr/bin/env ruby

# Test script for Content Generation API
# Run with: ruby test_content_generation_api.rb

require 'net/http'
require 'json'
require 'uri'

class ContentGenerationApiTest
  def initialize
    @base_url = 'http://localhost:3000/api/v1'
    @test_token = 'your_test_jwt_token_here' # Replace with actual token
  end

  def run_tests
    puts "🚀 Starting Content Generation API Tests"
    puts "=" * 50
    
    test_valid_request
    test_missing_description
    test_invalid_token
    test_different_content_types
    
    puts "\n✅ All tests completed!"
  end

  private

  def test_valid_request
    puts "\n📝 Test 1: Valid content generation request"
    
    response = make_request(
      description: "generate note on social media"
    )
    
    if response
      puts "✅ Status: #{response.code}"
      body = JSON.parse(response.body)
      puts "✅ Response has content: #{body.key?('content')}"
      puts "✅ Content length: #{body['content']&.length || 0} characters"
      puts "Sample content: #{body['content']&.slice(0, 100)}..." if body['content']
    else
      puts "❌ Request failed"
    end
  end

  def test_missing_description
    puts "\n📝 Test 2: Missing description parameter"
    
    response = make_request({})
    
    if response
      puts "✅ Status: #{response.code}"
      body = JSON.parse(response.body)
      puts "✅ Error code: #{body['code']}"
      puts "✅ Error message: #{body['message']}"
    else
      puts "❌ Request failed"
    end
  end

  def test_invalid_token
    puts "\n📝 Test 3: Invalid authentication token"
    
    response = make_request(
      { description: "test content" },
      token: "invalid_token"
    )
    
    if response
      puts "✅ Status: #{response.code}"
      body = JSON.parse(response.body)
      puts "✅ Error: #{body['error']}"
    else
      puts "❌ Request failed"
    end
  end

  def test_different_content_types
    puts "\n📝 Test 4: Different content types"
    
    test_cases = [
      "promote our new product launch",
      "how to increase social media engagement",
      "what's your favorite marketing strategy?",
      "announcing our new office location",
      "general social media post about our company"
    ]
    
    test_cases.each_with_index do |description, index|
      puts "\n  Test 4.#{index + 1}: #{description}"
      response = make_request(description: description)
      
      if response && response.code == '200'
        body = JSON.parse(response.body)
        puts "  ✅ Generated #{body['content']&.length || 0} characters"
      else
        puts "  ❌ Failed"
      end
    end
  end

  def make_request(params, token: @test_token)
    uri = URI("#{@base_url}/generate-content")
    http = Net::HTTP.new(uri.host, uri.port)
    
    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{token}"
    request['Content-Type'] = 'application/json'
    request.body = params.to_json
    
    begin
      response = http.request(request)
      return response
    rescue => e
      puts "❌ Request error: #{e.message}"
      return nil
    end
  end
end

# Run the tests
if __FILE__ == $0
  tester = ContentGenerationApiTest.new
  tester.run_tests
end