class Post < ApplicationRecord
  belongs_to :user

  validates :s3_url, presence: true
  validates :status, presence: true
end
