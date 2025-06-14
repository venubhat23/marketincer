# db/migrate/002_create_ai_generation_logs.rb
class CreateAiGenerationLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :ai_generation_logs do |t|
      t.references :contract, null: true, foreign_key: true
      t.text :description, null: false
      t.text :generated_content
      t.integer :status, default: 0
      t.text :error_message
      t.json :ai_response_data, default: {}
      
      t.timestamps
    end
    
    add_index :ai_generation_logs, :status
    add_index :ai_generation_logs, :created_at
  end
end
