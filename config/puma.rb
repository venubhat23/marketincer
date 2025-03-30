# Puma configuration for AWS Elastic Beanstalk
workers Integer(ENV.fetch("WEB_CONCURRENCY", 2))
threads_count = Integer(ENV.fetch("RAILS_MAX_THREADS", 5))
threads threads_count, threads_count

# Use the port provided by Elastic Beanstalk
port ENV.fetch("PORT", 3000)

# Environment settings
environment ENV.fetch("RAILS_ENV", "production")

# Directory for deployment
directory "/var/app/current"

# Allow puma to be restarted by `bin/rails restart` command
plugin :tmp_restart

# Run the Solid Queue supervisor inside of Puma if enabled
plugin :solid_queue if ENV["SOLID_QUEUE_IN_PUMA"]

# PID file location for EB
pidfile "/var/run/puma.pid"

# Logging configuration
stdout_redirect "/var/log/puma.stdout.log", "/var/log/puma.stderr.log", true

# Allow EB to properly manage the process
bind "unix:///var/run/puma.sock"
daemonize false

# Worker timeout (important for EB health checks)
worker_timeout 30

# Preload the application for faster worker boot
preload_app!

# Connection handling for database/redis
on_worker_boot do
  ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
  # Reconnect to Redis if needed
  if defined?(Sidekiq)
    Sidekiq.configure_client do |config|
      config.redis = { url: ENV['REDIS_URL'], size: Integer(ENV.fetch("SIDEKIQ_REDIS_POOL_SIZE", 5)) }
    end
  end
end

before_fork do
  ActiveRecord::Base.connection_pool.disconnect! if defined?(ActiveRecord)
end