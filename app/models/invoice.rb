class Invoice < ApplicationRecord
  belongs_to :user
  attribute :line_items, :jsonb, default: -> { [] }


  # Validations
  validates :company_name, presence: true
  validates :gst_number, presence: true
  validates :phone_number, presence: true
  validates :address, presence: true
  validates :status, presence: true

  # # Callback to calculate total_amount and total_price
  # before_save :calculate_totals

  # # Method to calculate total_amount and total_price based on line_items
  # def calculate_totals
  #   total_without_gst = line_items.inject(0) do |sum, item|
  #     sum + (item["quantity"].to_i * item["unit_price"].to_f)
  #   end
  #   gst_amount = total_without_gst * (gst_percentage / 100.0)
  #   self.total_amount = total_without_gst + gst_amount
  #   self.total_price = total_without_gst
  # end
end
