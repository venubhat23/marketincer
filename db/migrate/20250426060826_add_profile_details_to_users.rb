class AddProfileDetailsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
    add_column :users, :gst_name, :string
    add_column :users, :gst_number, :string
    add_column :users, :phone_number, :string
    add_column :users, :address, :text
    add_column :users, :company_website, :string
    add_column :users, :job_title, :string
    add_column :users, :work_email, :string
    add_column :users, :gst_percentage, :decimal, precision: 5, scale: 2, default: 18.0
  end
end