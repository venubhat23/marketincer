#!/usr/bin/env ruby

# Test script for Timezone and Delete Account APIs
# This script demonstrates how to test the new endpoints

require 'net/http'
require 'json'
require 'uri'

class SettingsAPITest
  BASE_URL = 'http://localhost:3000'
  
  def initialize(token = nil)
    @token = token
    @headers = {
      'Content-Type' => 'application/json',
      'Authorization' => "Bearer #{@token}"
    }
  end

  def login(email, password)
    uri = URI("#{BASE_URL}/api/v1/login")
    http = Net::HTTP.new(uri.host, uri.port)
    
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request.body = {
      email: email,
      password: password
    }.to_json

    response = http.request(request)
    result = JSON.parse(response.body)
    
    if result['status'] == 'success'
      @token = result['token']
      @headers['Authorization'] = "Bearer #{@token}"
      puts "✅ Login successful"
      puts "Token: #{@token[0..20]}..."
      return true
    else
      puts "❌ Login failed: #{result['message']}"
      return false
    end
  end

  def test_get_timezones
    puts "\n🌍 Testing GET /api/v1/settings/timezones"
    
    uri = URI("#{BASE_URL}/api/v1/settings/timezones")
    http = Net::HTTP.new(uri.host, uri.port)
    
    request = Net::HTTP::Get.new(uri)
    @headers.each { |key, value| request[key] = value }

    response = http.request(request)
    result = JSON.parse(response.body)
    
    puts "Status: #{response.code}"
    puts "Response: #{JSON.pretty_generate(result)}"
    
    if result['status'] == 'success' && result['data'].is_a?(Array)
      puts "✅ Timezones endpoint working correctly"
      puts "Found #{result['data'].length} timezones"
      return true
    else
      puts "❌ Timezones endpoint failed"
      return false
    end
  end

  def test_update_timezone(timezone = 'Asia/Kolkata')
    puts "\n⏰ Testing PATCH /api/v1/settings/timezone"
    
    uri = URI("#{BASE_URL}/api/v1/settings/timezone")
    http = Net::HTTP.new(uri.host, uri.port)
    
    request = Net::HTTP::Patch.new(uri)
    @headers.each { |key, value| request[key] = value }
    request.body = { timezone: timezone }.to_json

    response = http.request(request)
    result = JSON.parse(response.body)
    
    puts "Status: #{response.code}"
    puts "Request Body: #{request.body}"
    puts "Response: #{JSON.pretty_generate(result)}"
    
    if result['status'] == 'success'
      puts "✅ Timezone update successful"
      return true
    else
      puts "❌ Timezone update failed"
      return false
    end
  end

  def test_get_settings
    puts "\n⚙️ Testing GET /api/v1/settings (with timezone)"
    
    uri = URI("#{BASE_URL}/api/v1/settings")
    http = Net::HTTP.new(uri.host, uri.port)
    
    request = Net::HTTP::Get.new(uri)
    @headers.each { |key, value| request[key] = value }

    response = http.request(request)
    result = JSON.parse(response.body)
    
    puts "Status: #{response.code}"
    puts "Response: #{JSON.pretty_generate(result)}"
    
    if result['status'] == 'success' && result['data']['personal_information']['timezone']
      puts "✅ Settings endpoint includes timezone"
      return true
    else
      puts "❌ Settings endpoint missing timezone"
      return false
    end
  end

  def test_update_personal_info_with_timezone
    puts "\n👤 Testing PATCH /api/v1/settings/personal_information (with timezone)"
    
    uri = URI("#{BASE_URL}/api/v1/settings/personal_information")
    http = Net::HTTP.new(uri.host, uri.port)
    
    request = Net::HTTP::Patch.new(uri)
    @headers.each { |key, value| request[key] = value }
    request.body = {
      personal_information: {
        first_name: "Test",
        last_name: "User",
        timezone: "America/New_York"
      }
    }.to_json

    response = http.request(request)
    result = JSON.parse(response.body)
    
    puts "Status: #{response.code}"
    puts "Request Body: #{request.body}"
    puts "Response: #{JSON.pretty_generate(result)}"
    
    if result['status'] == 'success' && result['data']['timezone']
      puts "✅ Personal information update with timezone successful"
      return true
    else
      puts "❌ Personal information update with timezone failed"
      return false
    end
  end

  def test_delete_account(password)
    puts "\n🗑️ Testing DELETE /api/v1/settings/delete_account"
    puts "⚠️  WARNING: This will delete the test account!"
    
    print "Are you sure you want to test account deletion? (y/N): "
    confirmation = gets.chomp.downcase
    
    unless confirmation == 'y' || confirmation == 'yes'
      puts "Account deletion test skipped"
      return false
    end
    
    uri = URI("#{BASE_URL}/api/v1/settings/delete_account")
    http = Net::HTTP.new(uri.host, uri.port)
    
    request = Net::HTTP::Delete.new(uri)
    @headers.each { |key, value| request[key] = value }
    request.body = { password: password }.to_json

    response = http.request(request)
    result = JSON.parse(response.body)
    
    puts "Status: #{response.code}"
    puts "Request Body: #{request.body}"
    puts "Response: #{JSON.pretty_generate(result)}"
    
    if result['status'] == 'success'
      puts "✅ Account deletion successful"
      return true
    else
      puts "❌ Account deletion failed"
      return false
    end
  end

  def test_invalid_timezone
    puts "\n❌ Testing invalid timezone validation"
    
    uri = URI("#{BASE_URL}/api/v1/settings/timezone")
    http = Net::HTTP.new(uri.host, uri.port)
    
    request = Net::HTTP::Patch.new(uri)
    @headers.each { |key, value| request[key] = value }
    request.body = { timezone: 'Invalid/Timezone' }.to_json

    response = http.request(request)
    result = JSON.parse(response.body)
    
    puts "Status: #{response.code}"
    puts "Response: #{JSON.pretty_generate(result)}"
    
    if result['status'] == 'error'
      puts "✅ Invalid timezone properly rejected"
      return true
    else
      puts "❌ Invalid timezone validation failed"
      return false
    end
  end

  def run_all_tests(email, password)
    puts "🚀 Starting Settings API Tests"
    puts "=" * 50
    
    unless login(email, password)
      puts "Cannot proceed without authentication"
      return
    end

    # Test timezone endpoints
    test_get_timezones
    test_update_timezone('Asia/Kolkata')
    test_get_settings
    test_update_personal_info_with_timezone
    test_invalid_timezone
    
    # Test delete account (optional)
    puts "\n" + "=" * 50
    puts "Delete Account Test (Optional)"
    puts "=" * 50
    test_delete_account(password)
    
    puts "\n" + "=" * 50
    puts "🏁 Tests completed!"
    puts "=" * 50
  end
end

# Usage example
if __FILE__ == $0
  puts "Settings API Test Script"
  puts "=" * 30
  
  print "Enter email: "
  email = gets.chomp
  
  print "Enter password: "
  password = gets.chomp
  
  tester = SettingsAPITest.new
  tester.run_all_tests(email, password)
end