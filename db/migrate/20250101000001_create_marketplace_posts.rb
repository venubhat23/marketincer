class CreateMarketplacePosts < ActiveRecord::Migration[8.0]
  def change
    create_table :marketplace_posts do |t|
      t.string :title, null: false
      t.text :description
      t.string :category
      t.string :target_audience
      t.decimal :budget, precision: 10, scale: 2
      t.string :location
      t.string :platform
      t.string :languages
      t.date :deadline
      t.string :tags
      t.string :status, default: 'draft'
      t.string :brand_name
      t.string :media_url
      t.string :media_type
      t.integer :views_count, default: 0
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end

    add_index :marketplace_posts, :status
    add_index :marketplace_posts, :category
    add_index :marketplace_posts, :deadline
    add_index :marketplace_posts, :created_at
  end
end