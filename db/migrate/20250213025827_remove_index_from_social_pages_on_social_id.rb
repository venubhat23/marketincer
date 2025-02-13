class RemoveIndexFromSocialPagesOnSocialId < ActiveRecord::Migration[8.0]
  def change
    # Remove the index on social_id
    remove_index :social_pages, name: 'index_social_pages_on_social_id'
  end
end
