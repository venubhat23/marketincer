class AddIndexToShortUrlsLongUrl < ActiveRecord::Migration[8.0]
  def change
    add_index :short_urls, [:user_id, :long_url], name: 'index_short_urls_on_user_id_and_long_url'
  end
end