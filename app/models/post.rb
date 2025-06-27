# app/models/post.rb
class Post < ApplicationRecord
  belongs_to :user
  belongs_to :social_page, optional: true

  # validates :account_id, presence: true

  #validates :s3_url, presence: true
  validates :status, presence: true
end

