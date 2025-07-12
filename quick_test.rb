# Quick Test - Run this immediately in Rails console
# Replace YOUR_TOKEN with your actual access token

# Your token (replace this)
token = "YOUR_TOKEN_HERE"

# Quick service test
service = FacebookPagesService.new(token)
result = service.fetch_pages

puts "=== QUICK RESULTS ==="
puts "Found #{result.count} pages/profiles:"
result.each do |page|
  puts "- #{page[:name]} (#{page[:page_type]})"
end

# If no results, let's debug
if result.empty?
  puts "\n=== DEBUG INFO ==="
  
  # Check token
  debug_info = service.send(:debug_access_token)
  puts "Token valid: #{debug_info['data']['is_valid']}"
  puts "Scopes: #{debug_info['data']['scopes']}"
  
  # Check granular scopes
  if debug_info['data']['granular_scopes']
    ig_scope = debug_info['data']['granular_scopes'].find { |s| s['scope'] == 'instagram_basic' }
    if ig_scope
      puts "Instagram scope found: #{ig_scope}"
      puts "Target IDs: #{ig_scope['target_ids']}"
    else
      puts "No Instagram scope in granular_scopes"
    end
  else
    puts "No granular_scopes found"
  end
  
  # Try direct Facebook pages
  fb_response = HTTP.get(
    "https://graph.facebook.com/v18.0/me/accounts",
    params: { access_token: token }
  )
  fb_data = JSON.parse(fb_response.body)
  puts "Facebook pages: #{fb_data['data']&.count || 0}"
end