class CreatePosts < ActiveRecord::Migration[8.0]
  def change
    create_table :posts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :s3_url
      t.string :status
      t.string :hashtags
      t.text :note
      t.text :comments
      t.string :brand_name

      t.timestamps
    end
  end
end
