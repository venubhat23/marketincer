class AiGenerationLog < ApplicationRecord
  belongs_to :contract, optional: true

  # Status constants
  STATUS_PENDING    = 0
  STATUS_PROCESSING = 1
  STATUS_COMPLETED  = 2
  STATUS_FAILED     = 3
  STATUS_CANCELLED  = 4

  STATUS = {
    pending:    STATUS_PENDING,
    processing: STATUS_PROCESSING,
    completed:  STATUS_COMPLETED,
    failed:     STATUS_FAILED,
    cancelled:  STATUS_CANCELLED
  }.freeze

  validates :description, presence: true, length: { minimum: 10, maximum: 1000 }
  validates :status, presence: true
  validates :generated_content, presence: true, if: :completed?
  validates :error_message, presence: true, if: :failed?

  scope :recent, -> { order(created_at: :desc) }
  scope :for_contract, ->(contract_id) { where(contract_id: contract_id) }

  # Helper methods for status (replace enum helpers)
  def pending?    = status == STATUS_PENDING
  def processing? = status == STATUS_PROCESSING
  def completed?  = status == STATUS_COMPLETED
  def failed?     = status == STATUS_FAILED
  def cancelled?  = status == STATUS_CANCELLED

  def successful?
    completed? && generated_content.present?
  end
end