class PostPublisherWorker
  include Sidekiq::Worker
  sidekiq_options retry: 3
  
  def perform(post_id)
    post = Post.find_by(id: post_id)
    return unless post
    PostPublisherService.new(post).publish
  end
end
