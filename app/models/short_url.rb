class ShortUrl < ApplicationRecord
  belongs_to :user
  has_many :click_analytics, dependent: :destroy

  validates :long_url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid URL" }
  validates :short_code, presence: true, uniqueness: true, length: { minimum: 6, maximum: 10 }
  validates :clicks, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :custom_back_half, uniqueness: { case_sensitive: false }, allow_blank: true, length: { minimum: 3, maximum: 50 }

  before_validation :generate_short_code, on: :create
  before_validation :normalize_url
  before_validation :build_final_url
  after_create :generate_qr_code, if: :enable_qr?
  after_update :regenerate_qr_code, if: :should_regenerate_qr?
  after_update :rebuild_final_url, if: :utm_params_changed?

  scope :active, -> { where(active: true) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :recent, -> { order(created_at: :desc) }

  def short_url
    "https://api.marketincer.com/r/#{short_code}"
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

  def utm_params
    return {} unless enable_utm?
    
    params = {}
    params[:source] = utm_source if utm_source.present?
    params[:medium] = utm_medium if utm_medium.present?
    params[:campaign] = utm_campaign if utm_campaign.present?
    params[:term] = utm_term if utm_term.present?
    params[:content] = utm_content if utm_content.present?
    params
  end

  def qr_code_png
    return nil unless enable_qr?
    
    require 'rqrcode'
    require 'chunky_png'
    
    qrcode = RQRCode::QRCode.new(short_url)
    png = qrcode.as_png(
      bit_depth: 1,
      border_modules: 4,
      color_mode: ChunkyPNG::COLOR_GRAYSCALE,
      color: 'black',
      file: nil,
      fill: 'white',
      module_px_size: 6,
      resize_exactly_to: false,
      resize_gte_to: false,
      size: 120
    )
    png.to_s
  end

  private

  def generate_short_code
    return if short_code.present?
    
    if custom_back_half.present?
      # Check if custom back half is already taken
      if ShortUrl.exists?(short_code: custom_back_half)
        errors.add(:custom_back_half, "is already taken")
        return
      end
      self.short_code = custom_back_half
    else
      loop do
        self.short_code = SecureRandom.alphanumeric(6)
        break unless ShortUrl.exists?(short_code: short_code)
      end
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

  def build_final_url
    return unless long_url.present?
    
    if enable_utm? && utm_params.any?
      uri = URI.parse(long_url)
      existing_params = URI.decode_www_form(uri.query || "").to_h
      
      # Add UTM parameters
      utm_params.each do |key, value|
        existing_params["utm_#{key}"] = value if value.present?
      end
      
      uri.query = URI.encode_www_form(existing_params)
      self.final_url = uri.to_s
    else
      self.final_url = long_url
    end
  end

  def generate_qr_code
    return unless enable_qr?
    
    # Generate QR code file path
    qr_filename = "#{short_code}.png"
    qr_path = Rails.root.join('public', 'qr', qr_filename)
    
    # Create qr directory if it doesn't exist
    FileUtils.mkdir_p(File.dirname(qr_path))
    
    # Generate and save QR code
    File.open(qr_path, 'wb') do |file|
      file.write(qr_code_png)
    end
    
    # Update QR code URL
    self.update_column(:qr_code_url, "https://api.marketincer.com/qr/#{qr_filename}")
  rescue => e
    Rails.logger.error "Failed to generate QR code for #{short_code}: #{e.message}"
  end

  def should_regenerate_qr?
    enable_qr? && (saved_change_to_enable_qr? || saved_change_to_short_code?)
  end

  def utm_params_changed?
    saved_change_to_enable_utm? || saved_change_to_utm_source? || 
    saved_change_to_utm_medium? || saved_change_to_utm_campaign? || 
    saved_change_to_utm_term? || saved_change_to_utm_content?
  end

  def regenerate_qr_code
    generate_qr_code if enable_qr?
  end

  def rebuild_final_url
    build_final_url
    update_column(:final_url, final_url) if final_url_changed?
  end
end