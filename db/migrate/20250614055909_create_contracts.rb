class CreateContracts < ActiveRecord::Migration[8.0]
  def change
    create_table :contracts do |t|
      t.string :name, null: false
      t.integer :contract_type, default: 0
      t.integer :status, default: 0
      t.integer :category, default: 0
      t.date :date_created
      t.string :action, default: 'pending'
      t.text :content
      t.text :description
      t.json :metadata, default: {}
      
      t.timestamps
    end
    
    add_index :contracts, :name
    add_index :contracts, :contract_type
    add_index :contracts, :status
    add_index :contracts, :category
    add_index :contracts, :date_created
  end
end
