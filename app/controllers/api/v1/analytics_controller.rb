class Api::V1::AnalyticsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_short_url, only: [:show]

  # GET /api/v1/analytics/:short_code
  def show
    render json: {
      short_code: @short_url.short_code,
      short_url: @short_url.short_url,
      long_url: @short_url.long_url,
      title: @short_url.title,
      description: @short_url.description,
      total_clicks: @short_url.clicks,
      created_at: @short_url.created_at.iso8601,
      clicks_by_day: format_clicks_by_day(@short_url.clicks_by_day(30)),
      clicks_by_country: @short_url.clicks_by_country,
      clicks_by_device: @short_url.clicks_by_device,
      clicks_by_browser: @short_url.clicks_by_browser,
      recent_clicks: recent_clicks_data(@short_url),
      performance_metrics: {
        clicks_today: @short_url.clicks_today,
        clicks_this_week: @short_url.clicks_this_week,
        clicks_this_month: @short_url.clicks_this_month,
        average_clicks_per_day: calculate_average_clicks_per_day(@short_url),
        peak_day: find_peak_day(@short_url),
        conversion_rate: calculate_conversion_rate(@short_url)
      }
    }
  end

  # GET /api/v1/analytics/summary
  def summary
    @short_urls = current_user.short_urls.active

    render json: {
      user_id: current_user.id,
      total_urls: @short_urls.count,
      total_clicks: @short_urls.sum(:clicks),
      average_clicks_per_url: @short_urls.count > 0 ? (@short_urls.sum(:clicks).to_f / @short_urls.count).round(2) : 0,
      top_performing_urls: @short_urls.order(clicks: :desc).limit(10).map do |short_url|
        {
          short_code: short_url.short_code,
          short_url: short_url.short_url,
          long_url: short_url.long_url,
          clicks: short_url.clicks,
          created_at: short_url.created_at.iso8601
        }
      end,
      clicks_over_time: format_clicks_by_day(aggregate_clicks_by_day(@short_urls, 30)),
      device_breakdown: aggregate_device_breakdown(@short_urls),
      country_breakdown: aggregate_country_breakdown(@short_urls),
      browser_breakdown: aggregate_browser_breakdown(@short_urls)
    }
  end

  # GET /api/v1/analytics/export/:short_code
  def export
    @short_url = current_user.short_urls.find_by!(short_code: params[:short_code])

    csv_data = generate_csv_export(@short_url)

    send_data csv_data, 
              filename: "analytics_#{@short_url.short_code}_#{Date.current}.csv",
              type: 'text/csv',
              disposition: 'attachment'
  end

  private

  def set_short_url
    @short_url = current_user.short_urls.find_by!(short_code: params[:short_code])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Short URL not found" }, status: :not_found
  end

  def authenticate_user!
    token = request.headers['Authorization']&.split(' ')&.last

    if token.blank?
      render json: { error: "Authorization token required" }, status: :unauthorized
      return
    end

    begin
      decoded_token = JWT.decode(token, Rails.application.secret_key_base, true, algorithm: 'HS256')
      user_id = decoded_token[0]['user_id']
      @current_user = User.find(user_id)
    rescue JWT::DecodeError, ActiveRecord::RecordNotFound
      render json: { error: "Invalid or expired token" }, status: :unauthorized
    end
  end

  def current_user
    @current_user
  end

  def format_clicks_by_day(clicks_data)
    # Convert the groupdate result to the expected format
    clicks_data.transform_keys { |date| date.strftime('%Y-%m-%d') }
  end

  def recent_clicks_data(short_url)
    short_url.click_analytics.recent.limit(50).map do |click|
      {
        id: click.id,
        country: click.country,
        city: click.city,
        device_type: click.device_type,
        browser: click.browser,
        os: click.os,
        referrer: click.referrer,
        ip_address: click.ip_address&.gsub(/\.\d+$/, '.xxx'), # Mask last octet for privacy
        created_at: click.created_at.iso8601
      }
    end
  end

  def calculate_average_clicks_per_day(short_url)
    days_since_creation = (Time.current - short_url.created_at) / 1.day
    return 0 if days_since_creation < 1

    (short_url.clicks.to_f / days_since_creation).round(2)
  end

  def find_peak_day(short_url)
    clicks_by_day = short_url.clicks_by_day(30)
    return nil if clicks_by_day.empty?

    peak_date, peak_clicks = clicks_by_day.max_by { |_, clicks| clicks }
    {
      date: peak_date.strftime('%Y-%m-%d'),
      clicks: peak_clicks
    }
  end

  def calculate_conversion_rate(short_url)
    # This is a placeholder - in a real app you'd track conversions
    # For now, we'll use a random percentage as an example
    rand(1.0..15.0).round(2)
  end

  def aggregate_clicks_by_day(short_urls, days)
    end_date = Time.current
    start_date = days.days.ago.beginning_of_day

    ClickAnalytic.joins(:short_url)
                 .where(short_url: short_urls)
                 .where(created_at: start_date..end_date)
                 .group_by_day(:created_at, time_zone: 'UTC')
                 .count
  end

  def aggregate_device_breakdown(short_urls)
    ClickAnalytic.joins(:short_url)
                 .where(short_url: short_urls)
                 .where.not(device_type: [nil, ''])
                 .group(:device_type)
                 .count
                 .sort_by { |_, count| -count }
                 .to_h
  end

  def aggregate_country_breakdown(short_urls)
    ClickAnalytic.joins(:short_url)
                 .where(short_url: short_urls)
                 .where.not(country: [nil, ''])
                 .group(:country)
                 .count
                 .sort_by { |_, count| -count }
                 .to_h
  end

  def aggregate_browser_breakdown(short_urls)
    ClickAnalytic.joins(:short_url)
                 .where(short_url: short_urls)
                 .where.not(browser: [nil, ''])
                 .group(:browser)
                 .count
                 .sort_by { |_, count| -count }
                 .to_h
  end

  def generate_csv_export(short_url)
    require 'csv'

    CSV.generate(headers: true) do |csv|
      csv << ['Date', 'Time', 'Country', 'City', 'Device', 'Browser', 'OS', 'Referrer', 'IP Address']

      short_url.click_analytics.order(created_at: :desc).each do |click|
        csv << [
          click.created_at.strftime('%Y-%m-%d'),
          click.created_at.strftime('%H:%M:%S'),
          click.country,
          click.city,
          click.device_type,
          click.browser,
          click.os,
          click.referrer,
          click.ip_address&.gsub(/\.\d+$/, '.xxx') # Mask for privacy
        ]
      end
    end
  end
end