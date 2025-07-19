class CreateBids < ActiveRecord::Migration[8.0]
  def change
    create_table :bids do |t|
      t.references :marketplace_post, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.string :status, default: 'pending'
      t.text :message
      t.timestamps
    end

    add_index :bids, :status
    add_index :bids, [:marketplace_post_id, :user_id], unique: true
    add_index :bids, :created_at
  end
end