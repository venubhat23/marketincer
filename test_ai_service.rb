#!/usr/bin/env ruby

# Test script for AI Contract Generation Service
# Run this with: ruby test_ai_service.rb

require_relative 'config/environment'

puts "🤖 Testing AI Contract Generation Service"
puts "=" * 50

# Test descriptions
test_descriptions = [
  "Create a simple freelance web development contract for building an e-commerce website",
  "Generate an influencer collaboration agreement for Instagram posts about fitness products",
  "Create a basic NDA for a software development project",
  "Generate a product gifting agreement for a beauty brand collaboration"
]

# Test each description
test_descriptions.each_with_index do |description, index|
  puts "\n📝 Test #{index + 1}: #{description.truncate(60)}"
  puts "-" * 50
  
  begin
    service = AiContractGenerationService.new(description)
    result = service.generate
    
    if result.present?
      puts "✅ SUCCESS: Generated #{result.length} characters"
      puts "Preview: #{result.truncate(100)}..."
    else
      puts "❌ FAILED: No content generated"
    end
    
  rescue => e
    puts "❌ ERROR: #{e.message}"
  end
  
  # Small delay between tests
  sleep(1)
end

puts "\n🔧 API Key Status:"
puts "-" * 20

# Check API key availability
services = [
  { name: "OpenAI", key: ENV['OPENAI_API_KEY'] || Rails.application.credentials.openai_api_key },
  { name: "Hugging Face", key: ENV['HUGGINGFACE_API_KEY'] || Rails.application.credentials.huggingface_api_key },
  { name: "Groq", key: ENV['GROQ_API_KEY'] || Rails.application.credentials.groq_api_key },
  { name: "Together AI", key: ENV['TOGETHER_API_KEY'] || Rails.application.credentials.together_api_key }
]

services.each do |service|
  status = service[:key].present? ? "✅ Available" : "❌ Not configured"
  puts "#{service[:name]}: #{status}"
end

puts "\n📊 Recommendations:"
puts "-" * 20

if services.any? { |s| s[:key].present? }
  puts "✅ At least one API key is configured"
  puts "💡 The service will work with fallback to basic templates"
else
  puts "⚠️  No API keys configured"
  puts "💡 Service will only generate basic templates"
  puts "🔗 See AI_SETUP_GUIDE.md for setup instructions"
end

puts "\n🚀 Quick Setup Commands:"
puts "-" * 25
puts "1. Get Hugging Face token: https://huggingface.co/settings/tokens"
puts "2. Get Groq API key: https://console.groq.com"
puts "3. Add to Rails credentials:"
puts "   EDITOR='nano' rails credentials:edit"
puts "4. Or set environment variables:"
puts "   export HUGGINGFACE_API_KEY=your_token_here"

puts "\n✨ Test completed!"