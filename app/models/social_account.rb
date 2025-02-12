class SocialAccount < ApplicationRecord
  belongs_to :user
  has_many :social_pages, dependent: :destroy
  
  validates :provider, :access_token, presence: true
end
