class AddIsPageToSocialPages < ActiveRecord::Migration[8.0]
  def change
    add_column :social_pages, :is_page, :boolean, default: false
  end
end
