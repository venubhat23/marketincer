Rails.application.configure do
  config.lograge.enabled = true
  config.lograge.custom_options = lambda do |event|
    {
      time: Time.current,
      params: event.payload[:params]&.except('controller', 'action')
    }
  end
end