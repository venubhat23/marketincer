class User < ApplicationRecord
  has_secure_password

  validates :email, presence: true, 
                   uniqueness: { case_sensitive: false },
                   format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, 
                      length: { minimum: 6 }, 
                      if: :password_required?
  validates :phone_number, format: { with: /\A[\+]?[1-9][\d\s\-\(\)]{7,}\z/, message: "is invalid" }, 
                          allow_blank: true
  validates :avatar_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid URL" }, 
                        allow_blank: true
  validates :company_website, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid URL" }, 
                             allow_blank: true
  validates :timezone, presence: true, inclusion: { 
    in: ['Asia/Kolkata', 'America/New_York', 'America/Los_Angeles', 'Europe/London', 'Europe/Berlin', 
         'Asia/Tokyo', 'Asia/Shanghai', 'Australia/Sydney', 'Asia/Dubai', 'Asia/Singapore', 
         'Europe/Paris', 'America/Chicago', 'America/Denver', 'Pacific/Auckland', 'Africa/Cairo'],
    message: "is not a valid timezone" 
  }

  before_create :generate_activation_token
  
  has_many :posts
  has_many :social_accounts  # Add this line to define the relationship
  has_many :invoices
  has_many :purchase_orders
  has_many :marketplace_posts, dependent: :destroy
  has_many :bids, dependent: :destroy
  has_many :short_urls, dependent: :destroy

  def activation_token_expired?
    activation_sent_at < 24.hours.ago
  end

  def total_short_urls
    short_urls.count
  end

  def total_clicks
    short_urls.sum(:clicks)
  end

  def urls_created_this_month
    short_urls.where(created_at: 1.month.ago.beginning_of_month..Time.current).count
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
