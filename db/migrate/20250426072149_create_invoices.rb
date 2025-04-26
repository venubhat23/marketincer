class CreateInvoices < ActiveRecord::Migration[8.0]
  def change
    create_table :invoices do |t|
      t.references :user, null: false, foreign_key: true
      t.string :company_name
      t.string :gst_number
      t.string :phone_number
      t.text :address
      t.string :company_website
      t.string :job_title
      t.string :work_email
      t.decimal :gst_percentage
      t.jsonb :line_items
      t.decimal :total_amount
      t.string :status

      t.timestamps
    end
  end
end
