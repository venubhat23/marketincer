# app/jobs/post_publisher_job.rb
class PostPublisherJob
  include Sidekiq::Job

  def perform(post_id)
    post = Post.find_by(id: post_id)
    return unless post # Ensure post exists

    PostPublisherService.new(post).publish
  end
end
