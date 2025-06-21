# Use official Ruby base image with appropriate version
FROM ruby:3.2

# Set environment variables
ENV RAILS_ENV=production \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_PATH=/bundle \
    SECRET_KEY_BASE=5ee342bedf4744f06f520c3633b59b0f

# Install essential dependencies
RUN apt-get update -qq && \
    apt-get install -y build-essential libpq-dev nodejs yarn

# Set working directory
WORKDIR /app

# Install gems early (better layer caching)
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copy the rest of the app
COPY . .

# Run database migrations
# RUN bundle exec rails db:migrate

# Expose the port Rails will run on (ensure ECS maps this port too)
EXPOSE 3000

# Start the Rails server
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "3000"]
