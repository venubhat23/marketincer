class AddAccountIdToPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :posts, :account_id, :integer, null: true
  end
end
