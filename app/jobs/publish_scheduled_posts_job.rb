class PublishScheduledPostsJob < ApplicationJob
  queue_as :default

  def perform
    Post.where(status: "scheduled").where("scheduled_at <= ?", Time.current).find_each do |post|
      PostPublisherService.new(post).publish
      post.update(status: "published")
    end
  end
end
