class AddSettingsFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :bio, :text
    add_column :users, :avatar_url, :string
    add_column :users, :company_name, :string
  end
end