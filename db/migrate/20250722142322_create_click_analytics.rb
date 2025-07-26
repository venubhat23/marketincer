class CreateClickAnalytics < ActiveRecord::Migration[8.0]
  def change
    create_table :click_analytics do |t|
      t.references :short_url, null: false, foreign_key: true
      t.string :ip_address
      t.text :user_agent
      t.string :country
      t.string :city
      t.string :device_type
      t.string :browser
      t.string :os
      t.text :referrer
      t.json :additional_data, default: {}

      t.timestamps
    end

    add_index :click_analytics, :short_url_id
    add_index :click_analytics, :country
    add_index :click_analytics, :device_type
    add_index :click_analytics, :created_at
    add_index :click_analytics, [:short_url_id, :created_at]
  end
end