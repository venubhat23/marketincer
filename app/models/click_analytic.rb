class ClickAnalytic < ApplicationRecord
  belongs_to :short_url

  validates :short_url_id, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :by_country, ->(country) { where(country: country) }
  scope :by_device, ->(device_type) { where(device_type: device_type) }
  scope :by_date_range, ->(start_date, end_date) { where(created_at: start_date..end_date) }

  def self.create_from_request(short_url, request)
    user_agent_parser = UserAgent.parse(request.user_agent)
    
    create!(
      short_url: short_url,
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      country: extract_country_from_ip(request.remote_ip),
      city: extract_city_from_ip(request.remote_ip),
      device_type: determine_device_type(user_agent_parser),
      browser: user_agent_parser.browser,
      os: user_agent_parser.os,
      referrer: request.referer,
      additional_data: {
        user_agent_family: user_agent_parser.family,
        user_agent_version: user_agent_parser.version.to_s,
        os_version: user_agent_parser.os.version.to_s
      }
    )
  end

  private

  def self.extract_country_from_ip(ip_address)
    # In a real application, you would use a service like MaxMind GeoIP2
    # For now, we'll return a placeholder
    return 'Unknown' if ip_address.blank? || ip_address == '127.0.0.1'
    
    # This is a placeholder - in production you'd use:
    # require 'maxmind/geoip2'
    # reader = MaxMind::GeoIP2::Reader.new('/path/to/GeoLite2-Country.mmdb')
    # record = reader.country(ip_address)
    # record.country.name
    
    ['USA', 'India', 'Germany', 'Canada', 'UK', 'Australia', 'France', 'Japan'].sample
  end

  def self.extract_city_from_ip(ip_address)
    # Similar to country extraction, this would use GeoIP2 in production
    return 'Unknown' if ip_address.blank? || ip_address == '127.0.0.1'
    
    ['New York', 'Mumbai', 'Berlin', 'Toronto', 'London', 'Sydney', 'Paris', 'Tokyo'].sample
  end

  def self.determine_device_type(user_agent_parser)
    return 'Mobile' if user_agent_parser.mobile?
    return 'Tablet' if user_agent_parser.tablet?
    'Desktop'
  end
end