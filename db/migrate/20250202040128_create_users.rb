# db/migrate/YYYYMMDDHHMMSS_create_users.rb
class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :password_digest
      t.string :activation_token
      t.boolean :activated, default: false
      t.datetime :activation_sent_at

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :activation_token, unique: true
  end
end