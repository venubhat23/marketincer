# Sample data for testing the URL shortener interface

# Create a test user if it doesn't exist
user = User.find_or_create_by(email: 'test@example.com') do |u|
  u.password = 'password123'
  u.password_confirmation = 'password123'
  u.timezone = 'America/New_York'
end

puts "Created/found user: #{user.email}"

# Create some sample short URLs
sample_urls = [
  {
    long_url: 'https://www.google.com',
    title: 'Google Search',
    description: 'The world\'s most popular search engine',
    clicks: 45
  },
  {
    long_url: 'https://github.com',
    title: 'GitHub',
    description: 'Code hosting platform for developers',
    clicks: 23
  },
  {
    long_url: 'https://stackoverflow.com',
    title: 'Stack Overflow',
    description: 'Programming Q&A community',
    clicks: 67
  },
  {
    long_url: 'https://www.youtube.com',
    title: 'YouTube',
    description: 'Video sharing platform',
    clicks: 89
  },
  {
    long_url: 'https://www.linkedin.com',
    title: 'LinkedIn',
    description: 'Professional networking platform',
    clicks: 34
  },
  {
    long_url: 'https://www.twitter.com',
    title: 'Twitter',
    description: 'Social media microblogging platform',
    clicks: 56
  },
  {
    long_url: 'https://www.reddit.com',
    title: 'Reddit',
    description: 'Social news aggregation platform',
    clicks: 78
  },
  {
    long_url: 'https://www.amazon.com',
    title: 'Amazon',
    description: 'E-commerce marketplace',
    clicks: 91
  }
]

sample_urls.each do |url_data|
  short_url = user.short_urls.find_or_create_by(long_url: url_data[:long_url]) do |su|
    su.title = url_data[:title]
    su.description = url_data[:description]
    su.clicks = url_data[:clicks]
    su.active = true
  end
  
  puts "Created/found short URL: #{short_url.short_code} -> #{short_url.long_url}"
end

puts "Sample data creation completed!"
puts "Total URLs for user: #{user.short_urls.count}"
puts "Total clicks: #{user.total_clicks}"