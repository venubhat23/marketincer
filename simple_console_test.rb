# Simple Rails Console Test - Copy these commands one by one

# 1. Set your access token
ACCESS_TOKEN = "YOUR_ACTUAL_ACCESS_TOKEN_HERE"

# 2. Test the service
service = FacebookPagesService.new(ACCESS_TOKEN)

# 3. Debug token to see what we're working with
token_info = service.send(:debug_access_token)
puts "Token Info:"
puts JSON.pretty_generate(token_info)

# 4. Check if Instagram target_ids exist
if token_info && token_info["data"]["granular_scopes"]
  instagram_scope = token_info["data"]["granular_scopes"].find { |s| s["scope"] == "instagram_basic" }
  puts "\nInstagram Scope:"
  puts JSON.pretty_generate(instagram_scope)
  
  if instagram_scope && instagram_scope["target_ids"]
    puts "\nInstagram User IDs found: #{instagram_scope["target_ids"]}"
  else
    puts "\nNo Instagram target_ids found"
  end
end

# 5. Try to fetch pages using your service
puts "\n=== Fetching Pages ==="
pages = service.fetch_pages
puts "Found #{pages.count} pages/profiles"
pages.each { |p| puts "- #{p[:name]} (#{p[:page_type]})" }

# 6. Test direct API calls
puts "\n=== Direct API Tests ==="

# Facebook Pages
puts "Testing Facebook Pages API..."
fb_response = HTTP.get(
  "https://graph.facebook.com/v18.0/me/accounts",
  params: { access_token: ACCESS_TOKEN }
)
fb_data = JSON.parse(fb_response.body)
puts "Facebook Pages: #{fb_data['data']&.count || 0} found"

# User Profile
puts "Testing User Profile API..."
user_response = HTTP.get(
  "https://graph.facebook.com/v18.0/me?fields=id,name,email",
  params: { access_token: ACCESS_TOKEN }
)
user_data = JSON.parse(user_response.body)
puts "User: #{user_data['name']} (ID: #{user_data['id']})"

# Instagram Profile (if target_ids exist)
if token_info && token_info["data"]["granular_scopes"]
  instagram_scope = token_info["data"]["granular_scopes"].find { |s| s["scope"] == "instagram_basic" }
  if instagram_scope && instagram_scope["target_ids"]
    instagram_user_id = instagram_scope["target_ids"].first
    puts "Testing Instagram Profile API for ID: #{instagram_user_id}"
    
    ig_response = HTTP.get(
      "https://graph.facebook.com/v18.0/#{instagram_user_id}?fields=id,username,media_count,followers_count",
      params: { access_token: ACCESS_TOKEN }
    )
    ig_data = JSON.parse(ig_response.body)
    puts "Instagram Profile: #{ig_data['username']} (Followers: #{ig_data['followers_count']})"
  end
end