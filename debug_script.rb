# Debug Script - Find Instagram Pages/Profile Issues
# Run these commands in Rails console step by step

# Replace with your actual token
ACCESS_TOKEN = "YOUR_ACTUAL_ACCESS_TOKEN_HERE"

puts "=== DEBUG: Instagram Token Analysis ==="

# 1. Debug the access token
puts "1. Debugging access token..."
uri = URI("https://graph.facebook.com/v18.0/debug_token")
params = {
  input_token: ACCESS_TOKEN,
  access_token: "499798672825129|0972b471f1d251f8db7762be1db4613c"
}
uri.query = URI.encode_www_form(params)
response = Net::HTTP.get_response(uri)
token_data = JSON.parse(response.body)

puts "Token Debug Response:"
puts JSON.pretty_generate(token_data)

# 2. Check granular scopes specifically
puts "\n2. Analyzing granular scopes..."
if token_data["data"]["granular_scopes"]
  token_data["data"]["granular_scopes"].each do |scope|
    puts "Scope: #{scope['scope']}"
    puts "Target IDs: #{scope['target_ids']}" if scope['target_ids']
  end
else
  puts "No granular_scopes found"
end

# 3. Try to get user's Instagram accounts
puts "\n3. Checking user's Instagram accounts..."
ig_accounts_response = HTTP.get(
  "https://graph.facebook.com/v18.0/me/accounts?fields=id,name,instagram_business_account",
  params: { access_token: ACCESS_TOKEN }
)
ig_accounts_data = JSON.parse(ig_accounts_response.body)
puts "Instagram Business Accounts Response:"
puts JSON.pretty_generate(ig_accounts_data)

# 4. Try direct user profile
puts "\n4. Getting user profile..."
user_response = HTTP.get(
  "https://graph.facebook.com/v18.0/me?fields=id,name,email",
  params: { access_token: ACCESS_TOKEN }
)
user_data = JSON.parse(user_response.body)
puts "User Profile:"
puts JSON.pretty_generate(user_data)

# 5. Check what Instagram data we can get with current token
puts "\n5. Testing Instagram Basic API..."
user_id = token_data["data"]["user_id"]
puts "User ID from token: #{user_id}"

# Try to get Instagram data using the main user ID
ig_response = HTTP.get(
  "https://graph.facebook.com/v18.0/#{user_id}?fields=id,name",
  params: { access_token: ACCESS_TOKEN }
)
ig_data = JSON.parse(ig_response.body)
puts "Instagram User Data:"
puts JSON.pretty_generate(ig_data)

# 6. Check permissions
puts "\n6. Checking permissions..."
permissions_response = HTTP.get(
  "https://graph.facebook.com/v18.0/me/permissions",
  params: { access_token: ACCESS_TOKEN }
)
permissions_data = JSON.parse(permissions_response.body)
puts "Permissions:"
puts JSON.pretty_generate(permissions_data)

# 7. Alternative approach - check for Instagram connected accounts
puts "\n7. Alternative Instagram check..."
begin
  # Try to get Instagram accounts associated with user
  ig_alt_response = HTTP.get(
    "https://graph.facebook.com/v18.0/me?fields=id,name,accounts{id,name,instagram_business_account{id,name,username,profile_picture_url,biography,website,followers_count,media_count}}",
    params: { access_token: ACCESS_TOKEN }
  )
  ig_alt_data = JSON.parse(ig_alt_response.body)
  puts "Alternative Instagram Data:"
  puts JSON.pretty_generate(ig_alt_data)
rescue => e
  puts "Error with alternative approach: #{e.message}"
end

puts "\n=== END DEBUG ==="