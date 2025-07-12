# Rails Console Test Code for Facebook/Instagram API
# Copy and paste these commands in your Rails console

# Your access token from the debug info
ACCESS_TOKEN = "YOUR_ACCESS_TOKEN_HERE"  # Replace with your actual token

puts "=== Facebook/Instagram API Testing ==="
puts "Access Token: #{ACCESS_TOKEN[0..20]}..."

# Initialize the service
service = FacebookPagesService.new(ACCESS_TOKEN)

# Test 1: Debug Access Token
puts "\n=== 1. Debug Access Token ==="
token_debug = service.send(:debug_access_token)
puts "Token Debug Response:"
puts JSON.pretty_generate(token_debug) if token_debug

# Test 2: Fetch Pages (This will try Facebook first, then Instagram)
puts "\n=== 2. Fetch Pages/Profile ==="
begin
  pages = service.fetch_pages
  puts "Pages/Profile found: #{pages.count}"
  pages.each_with_index do |page, index|
    puts "\n--- Page #{index + 1} ---"
    puts "Name: #{page[:name]}"
    puts "Type: #{page[:page_type]}"
    puts "Social ID: #{page[:social_id]}"
    puts "Picture URL: #{page[:picture_url]}"
    puts "Access Token: #{page[:access_token] ? 'Present' : 'Missing'}"
  end
rescue => e
  puts "Error fetching pages: #{e.message}"
  puts e.backtrace.first(5)
end

# Test 3: Direct Facebook Pages API Call
puts "\n=== 3. Direct Facebook Pages API Call ==="
begin
  response = HTTP.get(
    "https://graph.facebook.com/v18.0/me/accounts?fields=id,name,access_token,category,category_list,tasks,picture.width(50).height(50)",
    params: { access_token: ACCESS_TOKEN }
  )
  fb_data = JSON.parse(response.body)
  puts "Facebook Pages Response:"
  puts JSON.pretty_generate(fb_data)
rescue => e
  puts "Error with Facebook Pages API: #{e.message}"
end

# Test 4: Direct Instagram Profile API Call
puts "\n=== 4. Direct Instagram Profile API Call ==="
begin
  # First get the Instagram User ID from token debug
  if token_debug && token_debug["data"]["granular_scopes"]
    instagram_scope = token_debug["data"]["granular_scopes"].find { |scope| scope["scope"] == "instagram_basic" }
    
    if instagram_scope && instagram_scope["target_ids"]
      instagram_user_id = instagram_scope["target_ids"].first
      puts "Instagram User ID: #{instagram_user_id}"
      
      # Fetch Instagram profile
      response = HTTP.get(
        "https://graph.facebook.com/v18.0/#{instagram_user_id}?fields=id,username,media_count,biography,followers_count,profile_picture_url",
        params: { access_token: ACCESS_TOKEN }
      )
      ig_data = JSON.parse(response.body)
      puts "Instagram Profile Response:"
      puts JSON.pretty_generate(ig_data)
    else
      puts "No Instagram target_ids found in token"
    end
  else
    puts "No granular_scopes found in token debug"
  end
rescue => e
  puts "Error with Instagram Profile API: #{e.message}"
end

# Test 5: User Profile API Call
puts "\n=== 5. User Profile API Call ==="
begin
  response = HTTP.get(
    "https://graph.facebook.com/v18.0/me?fields=id,name,email,picture.width(50).height(50)",
    params: { access_token: ACCESS_TOKEN }
  )
  user_data = JSON.parse(response.body)
  puts "User Profile Response:"
  puts JSON.pretty_generate(user_data)
rescue => e
  puts "Error with User Profile API: #{e.message}"
end

# Test 6: Check Token Permissions
puts "\n=== 6. Token Permissions Check ==="
begin
  response = HTTP.get(
    "https://graph.facebook.com/v18.0/me/permissions",
    params: { access_token: ACCESS_TOKEN }
  )
  permissions_data = JSON.parse(response.body)
  puts "Token Permissions:"
  puts JSON.pretty_generate(permissions_data)
rescue => e
  puts "Error checking permissions: #{e.message}"
end

puts "\n=== Testing Complete ==="