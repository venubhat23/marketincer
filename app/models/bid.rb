class Bid < ApplicationRecord
  belongs_to :marketplace_post
  belongs_to :user

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true, inclusion: { in: %w[pending accepted rejected] }
  validates :user_id, uniqueness: { scope: :marketplace_post_id, message: "can only bid once per post" }

  scope :pending, -> { where(status: 'pending') }
  scope :accepted, -> { where(status: 'accepted') }
  scope :rejected, -> { where(status: 'rejected') }
  scope :recent, -> { order(created_at: :desc) }

  def accept!
    update!(status: 'accepted')
  end

  def reject!
    update!(status: 'rejected')
  end

  def pending?
    status == 'pending'
  end

  def accepted?
    status == 'accepted'
  end

  def rejected?
    status == 'rejected'
  end

  def influencer_name
    "#{user.first_name} #{user.last_name}".strip.presence || user.email
  end
end