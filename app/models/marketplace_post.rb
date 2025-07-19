class MarketplacePost < ApplicationRecord
  belongs_to :user
  has_many :bids, dependent: :destroy

  validates :title, presence: true, length: { maximum: 255 }
  validates :description, presence: true
  validates :budget, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true, inclusion: { in: %w[draft published archived] }
  validates :category, presence: true, inclusion: { in: %w[A B] }
  validates :target_audience, presence: true, inclusion: { in: ['18–24', '24–30', '30–35', 'More than 35'] }
  validates :deadline, presence: true
  validates :location, presence: true
  validates :platform, presence: true
  validates :languages, presence: true

  before_save :set_brand_name

  scope :published, -> { where(status: 'published') }
  scope :draft, -> { where(status: 'draft') }
  scope :by_category, ->(category) { where(category: category) if category.present? }
  scope :by_target_audience, ->(audience) { where(target_audience: audience) if audience.present? }
  scope :recent, -> { order(created_at: :desc) }

  def increment_views!
    increment!(:views_count)
  end

  def bids_count
    bids.count
  end

  def pending_bids_count
    bids.where(status: 'pending').count
  end

  def accepted_bids_count
    bids.where(status: 'accepted').count
  end

  def rejected_bids_count
    bids.where(status: 'rejected').count
  end

  def tags_array
    tags.present? ? tags.split(',').map(&:strip) : []
  end

  def tags_array=(array)
    self.tags = array.join(', ')
  end

  private

  def set_brand_name
    # Set brand name from user profile if not provided
    if brand_name.blank? && user.present?
      self.brand_name = "#{user.first_name} #{user.last_name}".strip
      self.brand_name = user.email if brand_name.blank?
    end
  end
end