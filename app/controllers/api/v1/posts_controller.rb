class Api::V1::PostsController < ApplicationController
  before_action :authenticate_request # Ensure the user is authenticated

  # POST /api/v1/posts
  def create
    # Create a new post associated with the current_user
    post = @current_user.posts.new(post_params)

    if post.save
      render json: { message: 'Post created successfully', post: post,status: post.status }, status: :created
    else
      render json: { errors: post.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  # Permit the necessary post parameters
  def post_params
    params.require(:post).permit(:s3_url, :status, :hashtags, :note, :comments, :brand_name)
  end
end
