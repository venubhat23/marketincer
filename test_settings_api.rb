#!/usr/bin/env ruby

require 'net/http'
require 'json'
require 'uri'

# Configuration
BASE_URL = 'http://localhost:3000'
TEST_EMAIL = 'oliva@untitledui.com'
TEST_PASSWORD = 'password123'

class SettingsAPITester
  def initialize
    @base_url = BASE_URL
    @token = nil
  end

  def run_tests
    puts "🚀 Starting Settings API Tests..."
    puts "=" * 50
    
    # Step 1: Login to get JWT token
    puts "\n1. Testing Login..."
    login
    
    if @token
      puts "✅ Login successful! Token received."
      
      # Step 2: Get current settings
      puts "\n2. Testing GET /api/v1/settings..."
      get_settings
      
      # Step 3: Update personal information
      puts "\n3. Testing PATCH /api/v1/settings/personal_information..."
      update_personal_information
      
      # Step 4: Update company details
      puts "\n4. Testing PATCH /api/v1/settings/company_details..."
      update_company_details
      
      # Step 5: Test password change (with wrong current password)
      puts "\n5. Testing PATCH /api/v1/settings/change_password (wrong current password)..."
      test_wrong_password_change
      
      # Step 6: Test password change (with correct current password)
      puts "\n6. Testing PATCH /api/v1/settings/change_password (correct password)..."
      test_correct_password_change
      
    else
      puts "❌ Login failed! Cannot proceed with other tests."
    end
    
    puts "\n" + "=" * 50
    puts "🏁 Tests completed!"
  end

  private

  def login
    uri = URI("#{@base_url}/api/v1/login")
    http = Net::HTTP.new(uri.host, uri.port)
    
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request.body = {
      email: TEST_EMAIL,
      password: TEST_PASSWORD
    }.to_json
    
    response = http.request(request)
    
    if response.code == '200'
      data = JSON.parse(response.body)
      @token = data['token']
    else
      puts "❌ Login failed: #{response.code} - #{response.body}"
    end
  end

  def get_settings
    uri = URI("#{@base_url}/api/v1/settings")
    http = Net::HTTP.new(uri.host, uri.port)
    
    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Bearer #{@token}"
    request['Content-Type'] = 'application/json'
    
    response = http.request(request)
    
    if response.code == '200'
      puts "✅ GET Settings successful!"
      data = JSON.parse(response.body)
      puts "   Personal Info: #{data['data']['personal_information']['first_name']} #{data['data']['personal_information']['last_name']}"
      puts "   Company: #{data['data']['company_details']['name']}"
    else
      puts "❌ GET Settings failed: #{response.code} - #{response.body}"
    end
  end

  def update_personal_information
    uri = URI("#{@base_url}/api/v1/settings/personal_information")
    http = Net::HTTP.new(uri.host, uri.port)
    
    request = Net::HTTP::Patch.new(uri)
    request['Authorization'] = "Bearer #{@token}"
    request['Content-Type'] = 'application/json'
    request.body = {
      personal_information: {
        first_name: "Olivia",
        last_name: "Rhye",
        email: "olivia@untitledui.com",
        phone_number: "+1 (555) 123-4567",
        bio: "Senior Digital Marketing Specialist with expertise in growth hacking and data-driven strategies."
      }
    }.to_json
    
    response = http.request(request)
    
    if response.code == '200'
      puts "✅ Update Personal Information successful!"
      data = JSON.parse(response.body)
      puts "   Updated name: #{data['data']['first_name']} #{data['data']['last_name']}"
    else
      puts "❌ Update Personal Information failed: #{response.code} - #{response.body}"
    end
  end

  def update_company_details
    uri = URI("#{@base_url}/api/v1/settings/company_details")
    http = Net::HTTP.new(uri.host, uri.port)
    
    request = Net::HTTP::Patch.new(uri)
    request['Authorization'] = "Bearer #{@token}"
    request['Content-Type'] = 'application/json'
    request.body = {
      company_details: {
        company_name: "Untitled UI Inc",
        gst_name: "Untitled UI Incorporated",
        gst_number: "29ABCDE1234F1Z6",
        company_phone: "+1 (555) 000-1000",
        company_address: "456 Innovation Drive, Tech Hub, TH 54321",
        company_website: "https://www.untitledui.com"
      }
    }.to_json
    
    response = http.request(request)
    
    if response.code == '200'
      puts "✅ Update Company Details successful!"
      data = JSON.parse(response.body)
      puts "   Updated company: #{data['data']['name']}"
    else
      puts "❌ Update Company Details failed: #{response.code} - #{response.body}"
    end
  end

  def test_wrong_password_change
    uri = URI("#{@base_url}/api/v1/settings/change_password")
    http = Net::HTTP.new(uri.host, uri.port)
    
    request = Net::HTTP::Patch.new(uri)
    request['Authorization'] = "Bearer #{@token}"
    request['Content-Type'] = 'application/json'
    request.body = {
      current_password: "wrongpassword",
      new_password: "newpassword456",
      confirm_password: "newpassword456"
    }.to_json
    
    response = http.request(request)
    
    if response.code == '401'
      puts "✅ Wrong password correctly rejected!"
      data = JSON.parse(response.body)
      puts "   Error message: #{data['message']}"
    else
      puts "❌ Wrong password test failed: #{response.code} - #{response.body}"
    end
  end

  def test_correct_password_change
    uri = URI("#{@base_url}/api/v1/settings/change_password")
    http = Net::HTTP.new(uri.host, uri.port)
    
    request = Net::HTTP::Patch.new(uri)
    request['Authorization'] = "Bearer #{@token}"
    request['Content-Type'] = 'application/json'
    request.body = {
      current_password: TEST_PASSWORD,
      new_password: "newpassword456",
      confirm_password: "newpassword456"
    }.to_json
    
    response = http.request(request)
    
    if response.code == '200'
      puts "✅ Password change successful!"
      data = JSON.parse(response.body)
      puts "   Message: #{data['message']}"
    else
      puts "❌ Password change failed: #{response.code} - #{response.body}"
    end
  end
end

# Run the tests
if __FILE__ == $0
  tester = SettingsAPITester.new
  tester.run_tests
end