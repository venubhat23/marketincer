class AddUtmAndQrFieldsToShortUrls < ActiveRecord::Migration[8.0]
  def change
    add_column :short_urls, :custom_back_half, :string
    add_column :short_urls, :enable_utm, :boolean, default: false
    add_column :short_urls, :utm_source, :string
    add_column :short_urls, :utm_medium, :string
    add_column :short_urls, :utm_campaign, :string
    add_column :short_urls, :utm_term, :string
    add_column :short_urls, :utm_content, :string
    add_column :short_urls, :enable_qr, :boolean, default: false
    add_column :short_urls, :qr_code_url, :string
    add_column :short_urls, :final_url, :text

    add_index :short_urls, :custom_back_half, unique: true
    add_index :short_urls, :enable_utm
    add_index :short_urls, :enable_qr
  end
end