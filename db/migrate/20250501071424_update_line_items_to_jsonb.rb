class UpdateLineItemsToJsonb < ActiveRecord::Migration[6.1]
  def up
    # Check if column exists and is not JSONB
    if column_exists?(:invoices, :line_items) && !column_is_jsonb?(:invoices, :line_items)
      # Change column type to JSONB
      change_column :invoices, :line_items, :jsonb, default: '[]', using: 'line_items::jsonb'
    elsif !column_exists?(:invoices, :line_items)
      # Add JSONB column if it doesn't exist
      add_column :invoices, :line_items, :jsonb, default: '[]'
    end
    
    # Update any NULL values to empty array
    execute <<-SQL
      UPDATE invoices SET line_items = '[]'::jsonb WHERE line_items IS NULL;
    SQL
  end
  
  def down
    # No need for rollback
  end
  
  private
  
  def column_is_jsonb?(table, column)
    column_type = connection.select_value("SELECT data_type FROM information_schema.columns WHERE table_name = '#{table}' AND column_name = '#{column}'")
    column_type == 'jsonb'
  end
end