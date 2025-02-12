class CreateSocialAccounts < ActiveRecord::Migration[8.0]
  def change
    create_table :social_accounts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :provider # 'instagram', 'facebook'
      t.string :access_token
      t.json :user_info
      t.boolean :active, default: true

      t.timestamps
    end
  end
end