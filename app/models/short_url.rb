class ShortUrl < ApplicationRecord
  belongs_to :user
  has_many :click_analytics, dependent: :destroy

  validates :long_url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid URL" }
  validates :short_code, presence: true, uniqueness: true, length: { minimum: 6, maximum: 10 }
  validates :clicks, presence: true, numericality: { greater_than_or_equal_to: 0 }

  before_validation :generate_short_code, on: :create
  before_validation :normalize_url

  scope :active, -> { where(active: true) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :recent, -> { order(created_at: :desc) }

  # Find existing active short URL for a user and long URL
  scope :find_duplicate, ->(user_id, long_url) { 
    where(user_id: user_id, long_url: long_url, active: true) 
  }

  def short_url
    "https://short.ly/#{short_code}"
  end

  def increment_clicks!
    increment!(:clicks)
  end

  def clicks_by_day(days = 7)
    start_date = days.days.ago.beginning_of_day
    click_analytics
      .where(created_at: start_date..)
      .group_by_day(:created_at, time_zone: 'UTC')
      .count
  end

  def clicks_by_country
    click_analytics
      .where.not(country: [nil, ''])
      .group(:country)
      .count
      .sort_by { |_, count| -count }
      .to_h
  end

  def clicks_by_device
    click_analytics
      .where.not(device_type: [nil, ''])
      .group(:device_type)
      .count
      .sort_by { |_, count| -count }
      .to_h
  end

  def clicks_by_browser
    click_analytics
      .where.not(browser: [nil, ''])
      .group(:browser)
      .count
      .sort_by { |_, count| -count }
      .to_h
  end

  def clicks_today
    click_analytics.where(created_at: Date.current.all_day).count
  end

  def clicks_this_week
    click_analytics.where(created_at: 1.week.ago.beginning_of_week..Time.current).count
  end

  def clicks_this_month
    click_analytics.where(created_at: 1.month.ago.beginning_of_month..Time.current).count
  end

  private

  def generate_short_code
    return if short_code.present?
    
    loop do
      self.short_code = SecureRandom.alphanumeric(6)
      break unless ShortUrl.exists?(short_code: short_code)
    end
  end

  def normalize_url
    return unless long_url.present?
    
    # Add protocol if missing
    unless long_url.match?(/\Ahttps?:\/\//)
      self.long_url = "https://#{long_url}"
    end
    
    # Remove trailing slash
    self.long_url = long_url.chomp('/')
  end
end