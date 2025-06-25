class AiGenerationLog < ApplicationRecord
  belongs_to :contract, optional: true

  enum status: {
    pending: 0,
    processing: 1,
    completed: 2,
    failed: 3,
    cancelled: 4
  }

  validates :description, presence: true, length: { minimum: 10, maximum: 1000 }
  validates :status, presence: true
  validates :generated_content, presence: true, if: :completed?
  validates :error_message, presence: true, if: :failed?

  scope :recent, -> { order(created_at: :desc) }
  scope :for_contract, ->(contract_id) { where(contract_id: contract_id) }

  def successful?
    completed? && generated_content.present?
  end
end