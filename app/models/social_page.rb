# app/models/social_page.rb
class SocialPage < ApplicationRecord
  belongs_to :social_account
  has_many :posts
  
  validates :name, :social_id, :page_id, :access_token, presence: true
  validates :social_id, uniqueness: true
end
