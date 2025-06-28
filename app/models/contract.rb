# == Schema Information
# contract_type: integer
# status: integer
# category: integer
class Contract < ApplicationRecord
  # Add missing association for AI generation logs
  has_many :ai_generation_logs, dependent: :destroy

  CONTRACT_TYPES = {
    service: 0,
    collaboration: 1,
    sponsorship: 2,
    gifting: 3,
    employment: 4,
    nda: 5
  }.freeze

  STATUS = {
    draft: 0,
    sent: 1,
    signed: 2,
    cancelled: 3,
    expired: 4
  }.freeze

  CATEGORIES = {
    influencer: 0,
    brand: 1,
    agency: 2,
    freelancer: 3,
    employee: 4,
    vendor: 5
  }.freeze

  validates :name, presence: true, length: { minimum: 3, maximum: 255 }
  validates :contract_type, presence: true
  validates :status, presence: true
  validates :category, presence: true
  validates :description, presence: true, length: { minimum: 5, maximum: 1000 }

  scope :recent, -> { order(created_at: :desc) }
  scope :by_status, ->(status) { where(status: status) }
  scope :by_type, ->(type) { where(contract_type: type) }
  scope :search_by_name, ->(query) { where("name ILIKE ?", "%#{query}%") }

  def contract_type_sym
    CONTRACT_TYPES.key(self[:contract_type])
  end

  def status_sym
    STATUS.key(self[:status])
  end

  def category_sym
    CATEGORIES.key(self[:category])
  end

  # Cache the contract templates in a class variable for better performance
  def self.contract_templates
    @@contract_templates ||= [
      {
        id: 1,
        name: "Service Agreement",
        description: "A standard service agreement between a service provider and client.",
        contract_type: "service",
        category: "freelancer",
        template: "SERVICE AGREEMENT\n\nThis Service Agreement ..."
      },
      {
        id: 2,
        name: "Non-Disclosure Agreement",
        description: "A confidentiality agreement to protect sensitive business information.",
        contract_type: "nda",
        category: "vendor",
        template: "NON-DISCLOSURE AGREEMENT\n\nThis Non-Disclosure Agreement ..."
      },
      {
        id: 3,
        name: "Employment Contract",
        description: "A comprehensive employment agreement outlining terms, conditions, and responsibilities for new hires.",
        contract_type: "employment",
        category: "employee",
        template: "EMPLOYMENT AGREEMENT\n\nThis Employment Agreement ..."
      },
      {
        id: 4,
        name: "Freelance Contract",
        description: "An independent contractor agreement for freelance work including project scope and payment terms.",
        contract_type: "service",
        category: "freelancer",
        template: "FREELANCE CONTRACTOR AGREEMENT\n\nThis Agreement is between ..."
      }
    ]
  end
end