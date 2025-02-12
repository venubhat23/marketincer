class CreateSocialPages < ActiveRecord::Migration[8.0]
  def change
    create_table :social_pages do |t|
      t.references :social_account, null: false, foreign_key: true
      t.string :name
      t.string :username
      t.string :page_type # 'ig_business', 'facebook_page'
      t.string :social_id
      t.string :page_id
      t.string :picture_url
      t.string :access_token
      t.boolean :connected, default: false
      t.json :page_info

      t.timestamps
    end
    
    add_index :social_pages, :social_id, unique: true
  end
end
