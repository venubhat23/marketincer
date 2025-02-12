class AddSocialPageToPosts < ActiveRecord::Migration[8.0]
  def change
    add_reference :posts, :social_page, foreign_key: true
  end
end

