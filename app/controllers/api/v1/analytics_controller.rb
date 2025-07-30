class Api::V1::AnalyticsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_short_url, only: [:show]

  # GET /api/v1/analytics/:short_code
  def show
    # Handle demo/test data for development
    if params[:short_code] == 'demo' || Rails.env.development?
      return render json: demo_analytics_data
    end
    render json: {
      success: true,
      data: {
        basic_info: {
          short_code: @short_url.short_code,
          short_url: @short_url.short_url,
          long_url: @short_url.long_url,
          title: @short_url.title,
          description: @short_url.description,
          created_at: @short_url.created_at.iso8601,
          qr_code_url: @short_url.qr_code_url
        },
        performance_metrics: {
          total_clicks: @short_url.clicks,
          clicks_today: @short_url.clicks_today,
          clicks_this_week: @short_url.clicks_this_week,
          clicks_this_month: @short_url.clicks_this_month,
          average_clicks_per_day: calculate_average_clicks_per_day(@short_url),
          peak_day: find_peak_day(@short_url),
          conversion_rate: calculate_conversion_rate(@short_url)
        },
        analytics_data: {
          clicks_by_day: format_clicks_by_day(@short_url.clicks_by_day(30)),
          clicks_by_country: @short_url.clicks_by_country,
          clicks_by_device: @short_url.clicks_by_device,
          clicks_by_browser: @short_url.clicks_by_browser,
          recent_clicks: recent_clicks_data(@short_url),
          top_referrers: get_top_referrers(@short_url),
          hourly_distribution: get_hourly_distribution(@short_url)
        }
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

  def get_top_referrers(short_url)
    short_url.click_analytics
             .where.not(referrer: [nil, ''])
             .group(:referrer)
             .count
             .sort_by { |_, count| -count }
             .first(10)
             .to_h
  end

  def get_hourly_distribution(short_url)
    short_url.click_analytics
             .group_by_hour_of_day(:created_at, time_zone: 'UTC')
             .count
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

  def demo_analytics_data
    {
      success: true,
      data: {
        basic_info: {
          short_code: 'demo123',
          short_url: 'https://api.marketincer.com/r/demo123',
          long_url: 'https://example.com/very/long/url/with/parameters?utm_source=demo&utm_medium=test',
          title: 'Demo Link',
          description: 'This is a demo link for testing',
          created_at: 3.days.ago.iso8601,
          qr_code_url: 'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=demo'
        },
        performance_metrics: {
          total_clicks: 1247,
          clicks_today: 23,
          clicks_this_week: 156,
          clicks_this_month: 892,
          average_clicks_per_day: 41.6,
          peak_day: '2024-01-15',
          conversion_rate: 12.5
        },
        analytics_data: {
          clicks_by_day: {
            '2024-01-10' => 45,
            '2024-01-11' => 52,
            '2024-01-12' => 38,
            '2024-01-13' => 67,
            '2024-01-14' => 41,
            '2024-01-15' => 89,
            '2024-01-16' => 23
          },
          clicks_by_country: {
            'United States' => 456,
            'Canada' => 234,
            'United Kingdom' => 187,
            'Germany' => 142,
            'France' => 98,
            'Australia' => 76,
            'Japan' => 54
          },
          clicks_by_device: {
            'Mobile' => 678,
            'Desktop' => 423,
            'Tablet' => 146
          },
          clicks_by_browser: {
            'Chrome' => 567,
            'Safari' => 234,
            'Firefox' => 156,
            'Edge' => 134,
            'Opera' => 89,
            'Other' => 67
          },
          recent_clicks: [
            {
              country: 'United States',
              device_type: 'Mobile',
              browser: 'Chrome',
              created_at: 2.hours.ago.iso8601
            },
            {
              country: 'Canada',
              device_type: 'Desktop',
              browser: 'Safari',
              created_at: 3.hours.ago.iso8601
            },
            {
              country: 'United Kingdom',
              device_type: 'Mobile',
              browser: 'Firefox',
              created_at: 4.hours.ago.iso8601
            },
            {
              country: 'Germany',
              device_type: 'Tablet',
              browser: 'Chrome',
              created_at: 5.hours.ago.iso8601
            },
            {
              country: 'France',
              device_type: 'Desktop',
              browser: 'Edge',
              created_at: 6.hours.ago.iso8601
            }
          ],
          top_referrers: {
            'google.com' => 234,
            'facebook.com' => 156,
            'twitter.com' => 89,
            'linkedin.com' => 67,
            'reddit.com' => 45
          },
          hourly_distribution: {
            0 => 12, 1 => 8, 2 => 5, 3 => 3, 4 => 4, 5 => 7,
            6 => 15, 7 => 28, 8 => 45, 9 => 67, 10 => 78, 11 => 89,
            12 => 95, 13 => 87, 14 => 92, 15 => 76, 16 => 68, 17 => 54,
            18 => 43, 19 => 38, 20 => 32, 21 => 28, 22 => 22, 23 => 18
          }
        }
      }
    }
  end
end