# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create a sample user for testing the Settings API
user = User.find_or_create_by!(email: 'oliva@untitledui.com') do |u|
  u.first_name = 'Oliva'
  u.last_name = 'Rhye'
  u.password = 'password123'
  u.phone_number = '+1 (555) 000-0000'
  u.bio = 'Digital marketing specialist with 5+ years of experience in growth strategies.'
  u.avatar_url = 'https://example.com/avatars/oliva.jpg'
  u.company_name = 'Untitled UI'
  u.gst_name = 'Untitled UI Private Limited'
  u.gst_number = '29ABCDE1234F1Z5'
  u.address = '123 Business Street, Tech City, TC 12345'
  u.company_website = 'https://www.untitledui.com'
  u.activated = true
end

puts "Sample user created: #{user.email}"
