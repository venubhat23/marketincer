# app/jobs/scheduled_post_publish_job.rb
class ScheduledPostPublishJob
  include Sidekiq::Job
  sidekiq_options retry: 3

  def perform(post_id)
    # Find the post
    post = Post.find_by(id: post_id)
    
    # Return early if post is not found or no longer scheduled
    return unless post && post.status == 'scheduled'

    begin
      # Use the PostPublisherService to publish the post
      publisher = PostPublisherService.new(post)
      publisher.publish

      # Update post status
      post.update(status: 'published')
    rescue StandardError => e
      # Log the error
      Rails.logger.error("Failed to publish scheduled post #{post_id}: #{e.message}")
      
      # Optionally update post with error status
      post.update(
        status: 'publish_failed', 
        publish_log: e.message
      )
    end
  end
end