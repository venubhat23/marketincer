class Contract < ApplicationRecord
  validates :name, presence: true
  validates :contract_type, presence: true

  scope :contracts_only, -> { where(category: 'created') }
  scope :templates_only, -> { where(category: 'template') }
  scope :search_by_name, ->(query) { where("name ILIKE ?", "%#{query}%") }

  before_create :set_defaults

  private

  def set_defaults
    self.date_created ||= Date.current
    self.action ||= category == 'template' ? 'ready' : 'pending'
  end
end

