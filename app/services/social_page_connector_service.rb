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

  private

  def find_or_create_social_account
    @user.social_accounts.find_or_create_by!(
      provider: @page_params[:page_type] == 'ig_business' ? 'instagram' : 'facebook'
    ) do |account|
      account.access_token = @page_params[:access_token]
      account.user_info = @page_params[:user]
    end
  end

  def create_social_page(social_account)
    social_account.social_pages.create!(
      name: @page_params[:name],
      username: @page_params[:username],
      page_type: @page_params[:page_type],
      social_id: @page_params[:social_id],
      page_id: @page_params[:page_id],
      picture_url: @page_params[:picture_url],
      access_token: @page_params[:access_token],
      connected: true,
      page_info: @page_params[:user]
    )
  end
end