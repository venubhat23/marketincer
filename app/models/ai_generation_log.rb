class AiGenerationLog < ApplicationRecord
  belongs_to :contract, optional: true
  
  validates :description, presence: true
  validates :status, inclusion: { in: %w[pending processing completed failed] }
  
  enum status: { pending: 0, processing: 1, completed: 2, failed: 3 }
end
