class AddTimezoneToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :timezone, :string, default: 'Asia/Kolkata'
  end
end