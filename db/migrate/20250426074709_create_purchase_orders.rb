class CreatePurchaseOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :purchase_orders do |t|
      t.references :user, null: false, foreign_key: true
      t.string :company_name
      t.string :gst_number
      t.string :phone_number
      t.string :address
      t.string :company_website
      t.string :job_title
      t.string :work_email
      t.decimal :gst_percentage
      t.string :status
      t.decimal :total_amount
      t.string :order_number
      t.jsonb :line_items

      t.timestamps
    end
  end
end
