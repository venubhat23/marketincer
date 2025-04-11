require 'sidekiq'
require 'sidekiq/web'

# Configure Sidekiq Web UI with session middleware
Sidekiq::Web.use ActionDispatch::Cookies
Sidekiq::Web.use ActionDispatch::Session::CookieStore, key: '_interslice_session'

# Basic authentication for Sidekiq Web UI (hardcoded credentials for local use)
Sidekiq::Web.use Rack::Auth::Basic do |username, password|
  ActiveSupport::SecurityUtils.secure_compare(username, "admin") &&
    ActiveSupport::SecurityUtils.secure_compare(password, "password123")
end

redis_url = "redis://marketincersidekiqcache-oysgtt.serverless.use2.cache.amazonaws.com:6379"

# Upstash Redis Configuration
Sidekiq.configure_server do |config|
  config.redis = {
    url: redis_url
  }
end

Sidekiq.configure_client do |config|
  config.redis = {
    url: redis_url
  }
end
