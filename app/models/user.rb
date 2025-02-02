# app/models/user.rb
class User < ApplicationRecord
  has_secure_password

  validates :email, presence: true, 
                   uniqueness: { case_sensitive: false },
                   format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, 
                      length: { minimum: 6 }, 
                      if: :password_required?

  before_create :generate_activation_token
  
  has_many :posts

  def activation_token_expired?
    activation_sent_at < 24.hours.ago
  end
  
  private

  def generate_activation_token
    self.activation_token = SecureRandom.urlsafe_base64
    self.activation_sent_at = Time.current
  end

  def password_required?
    !persisted? || password.present?
  end
end