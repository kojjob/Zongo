class CropListingInquiry < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :crop_listing
  has_one :listing_owner, through: :crop_listing, source: :user

  # Validations
  validates :message, presence: true
  validates :status, presence: true
  validates :quantity, numericality: { greater_than: 0 }, allow_nil: true
  validates :offered_price, numericality: { greater_than: 0 }, allow_nil: true

  # Enums
  enum :status, {
    pending: 0,
    responded: 1,
    accepted: 2,
    rejected: 3,
    expired: 4
  }, default: :pending

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :unread, -> { where(read: false) }
  scope :by_listing, ->(listing_id) { where(crop_listing_id: listing_id) }

  # Callbacks
  after_create :notify_listing_owner

  # Methods
  def mark_as_read!
    update(read: true)
  end

  def accept!
    update(status: :accepted, responded_at: Time.current)
    # Additional logic for accepting an inquiry
  end

  def reject!
    update(status: :rejected, responded_at: Time.current)
  end

  def respond!(response_message)
    update(
      status: :responded,
      response: response_message,
      responded_at: Time.current
    )
  end

  def expired?
    created_at < 7.days.ago && pending?
  end

  private

  def notify_listing_owner
    # Logic to notify the listing owner about the new inquiry
    # This could be implemented using ActionCable, email notifications, etc.
  end
end
