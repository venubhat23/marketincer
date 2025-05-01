class Invoice < ApplicationRecord
  belongs_to :user
  
  # For PostgreSQL JSONB column
  # No need for serialize with JSONB columns
  
  # Ensure default empty array
  after_initialize :set_default_line_items, if: :new_record?
  before_save :ensure_line_items_array
  
  # Validations
  validates :company_name, presence: true
  validates :gst_number, presence: true
  validates :phone_number, presence: true
  validates :address, presence: true
  validates :status, presence: true
  
  # Method to calculate total_amount based on line_items and GST
  def calculate_totals
    total_without_gst = 0
    
    if line_items.is_a?(Array)
      total_without_gst = line_items.sum do |item|
        quantity = item["quantity"].to_i || item[:quantity].to_i || 0
        price = item["unit_price"].to_f || item[:unit_price].to_f || 0
        quantity * price
      end
    end
    
    gst_amount = total_without_gst * (gst_percentage.to_f / 100.0)
    self.total_amount = total_without_gst + gst_amount
  end
  
  private
  
  def set_default_line_items
    self.line_items ||= []
  end
  
  def ensure_line_items_array
    self.line_items = [] if self.line_items.nil?
  end
end