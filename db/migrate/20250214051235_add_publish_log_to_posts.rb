class AddPublishLogToPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :posts, :publish_log, :text
  end
end
