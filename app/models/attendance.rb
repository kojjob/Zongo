class Attendance < ApplicationRecord
  belongs_to :event
  belongs_to :user

  validates :user_id, uniqueness: { scope: :event_id, message: "is already attending this event" }

  before_create :generate_ticket_code

  # Scopes
  scope :confirmed, -> { where(status: "confirmed") }
  scope :checked_in, -> { where.not(checked_in_at: nil) }
  scope :pending, -> { where(status: "pending") }
  scope :cancelled, -> { where(status: "cancelled") }

  def confirmed?
    status == "confirmed"
  end

  def pending?
    status == "pending"
  end

  def cancelled?
    status == "cancelled"
  end

  def checked_in?
    checked_in_at.present?
  end

  def check_in!
    update(checked_in_at: Time.current)
  end

  def cancel!
    update(status: "cancelled")
  end

  private

  def generate_ticket_code
    self.ticket_code ||= SecureRandom.alphanumeric(8).upcase
  end
end
