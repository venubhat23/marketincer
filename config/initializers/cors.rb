# Be sure to restart your server when you modify this file.

# Handle Cross-Origin Resource Sharing (CORS) to accept cross-origin Ajax requests.
# More: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'https://app.marketincer.com'  # Only allow frontend origin

    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: false
  end
end
