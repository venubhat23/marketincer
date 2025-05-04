class LinkedinPageConnectorService
  def initialize(user, page_params)
    @user = user
    @page_params = page_params
  end

  def connect
    social_account = find_or_create_linkedin_account
    create_linkedin_page(social_account)
  end

  def disconnect
    ActiveRecord::Base.transaction do
      social_page = @user.social_accounts
                         .find_by(id: @page_params[:social_account_id], provider: 'linkedin')
                         &.social_pages
                         &.find_by(id: @page_params[:id])

      return { success: false, error: "LinkedIn Page not found" } unless social_page

      social_account = social_page.social_account
      social_page.destroy!

      if social_account.social_pages.count.zero?
        social_account.destroy!
      end

      { success: true }
    rescue ActiveRecord::RecordNotFound
      { success: false, error: "Invalid LinkedIn social_account_id or page_id" }
    rescue => e
      { success: false, error: "Failed to disconnect LinkedIn page: #{e.message}" }
    end
  end

  private

  def find_or_create_linkedin_account
    @user.social_accounts.find_or_create_by!(provider: 'linkedin') do |account|
      account.access_token = @page_params[:access_token]
      account.user_info = @page_params[:user_info] || {}
      account.active = true
    end
  end

  def create_linkedin_page(social_account)
    existing_page = social_account.social_pages.find_by(
      social_id: @page_params[:user_info]&.dig('sub')
    )

    if existing_page.present?
      Rails.logger.info "LinkedIn Page already exists for user: #{@page_params[:user_info]&.dig('name')}"
      return existing_page
    end

    social_account.social_pages.create!(
      name: @page_params[:user_info]&.dig('name'),
      username: @page_params[:user_info]&.dig('email'),
      page_type: 'linkedin',
      social_id: @page_params[:user_info]&.dig('sub'),
      page_id: @page_params[:user_info]&.dig('sub'),
      picture_url: @page_params[:picture_url],
      access_token: @page_params[:access_token],
      connected: true,
      page_info: @page_params[:user_info] || {}
    )
  end
end