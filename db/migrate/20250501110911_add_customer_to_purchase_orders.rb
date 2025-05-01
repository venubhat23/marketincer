class AddCustomerToPurchaseOrders < ActiveRecord::Migration[6.1] # or [7.0] depending on your version
  def change
    add_column :purchase_orders, :customer, :string
  end
end
