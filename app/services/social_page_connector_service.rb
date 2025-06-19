# app/services/social_page_connector_service.rb
class SocialPageConnectorService
  def initialize(user, page_params)
    @user = user
    @page_params = page_params
  end

  def connect
    social_account = find_or_create_social_account
    create_social_page(social_account)
  end


  def disconnect
    debuger
    ActiveRecord::Base.transaction do
      social_page = @user.social_accounts
                         .find_by(id: @page_params[:social_account_id])
                         &.social_pages
                         &.find_by(id: @page_params[:id])

      return { success: false, error: "Social Page not found" } unless social_page

      social_account = social_page.social_account
      social_page.destroy!

      # If the social account has no more connected pages, delete the account
      if social_account.social_pages.count.zero?
        social_account.destroy!
      end

      return { success: true }
    rescue ActiveRecord::RecordNotFound
      return { success: false, error: "Invalid social_account_id or id" }
    rescue => e
      return { success: false, error: "Failed to disconnect: #{e.message}" }
    end
  end

  private

  def find_or_create_social_account
    return @user.social_accounts.find_or_create_by!(
      provider: @page_params[:page_type] == 'ig_business' ? 'instagram' : 'facebook'
    ) do |account|
      account.access_token = @page_params[:access_token]
      account.user_info = @page_params[:user]
    end
  end

  def create_social_page(social_account)
    
    existing_page = social_account.social_pages.find_by(
      social_id: @page_params[:social_id],
      page_id: @page_params[:page_id]
    )

    if existing_page.present?
      Rails.logger.info "SocialPage already exists for social_id: #{@page_params[:social_id]} and page_id: #{@page_params[:page_id]}"
      return existing_page
    end
    social_account.social_pages.create!(
      name: @page_params[:name],
      username: @page_params[:username],
      page_type: "instagram",
      social_id: @page_params[:social_id],
      page_id: @page_params[:page_id],
      picture_url: @page_params[:picture_url],
      access_token: @page_params[:access_token],
      connected: true,
      page_info: @page_params[:user],
      is_page: @page_params[:is_page]
    )
  end
end

