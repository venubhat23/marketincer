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

# Upstash Redis Configuration
Sidekiq.configure_server do |config|
  config.redis = {
    url: "rediss://fine-dane-48514.upstash.io",
    password: "Ab2CAAIjcDE5MzQxNWU0OTc0NjU0MTlhYTY4YWI2YWVkZDcxN2JkZHAxMA",
    ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }
  }
end

Sidekiq.configure_client do |config|
  config.redis = {
    url: "rediss://fine-dane-48514.upstash.io",
    password: "Ab2CAAIjcDE5MzQxNWU0OTc0NjU0MTlhYTY4YWI2YWVkZDcxN2JkZHAxMA",
    ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }
  }
end
