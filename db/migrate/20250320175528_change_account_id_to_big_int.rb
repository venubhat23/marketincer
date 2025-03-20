class ChangeAccountIdToBigInt < ActiveRecord::Migration[8.0]
  def change
    change_column :posts, :account_id, :bigint
  end
end
