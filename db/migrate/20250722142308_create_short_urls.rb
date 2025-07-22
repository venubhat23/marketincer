class CreateShortUrls < ActiveRecord::Migration[8.0]
  def change
    create_table :short_urls do |t|
      t.references :user, null: false, foreign_key: true
      t.text :long_url, null: false
      t.string :short_code, null: false
      t.integer :clicks, default: 0
      t.json :analytics_data, default: {}
      t.boolean :active, default: true
      t.string :title
      t.text :description

      t.timestamps
    end

    add_index :short_urls, :short_code, unique: true
    add_index :short_urls, :user_id
    add_index :short_urls, :created_at
    add_index :short_urls, :active
  end
end
