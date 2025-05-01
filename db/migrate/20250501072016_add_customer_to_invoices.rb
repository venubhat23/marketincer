class AddCustomerToInvoices < ActiveRecord::Migration[8.0]
  def change
    add_column :invoices, :customer, :string
  end
end
