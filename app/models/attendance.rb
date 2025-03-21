class Attendance < ApplicationRecord
  belongs_to :user
  belongs_to :event
  has_many :event_tickets, dependent: :restrict_with_error
  
  # Statuses
  enum :status, {
    registered: 0,
    confirmed: 1,
    checked_in: 2,
    cancelled: 3,
    no_show: 4
  }, default: :registered, scope: :event
  
  # Validations
  validates :user_id, uniqueness: { scope: :event_id, message: "is already registered for this event" }
  
  # Callbacks
  before_save :set_checked_in_time, if: -> { status_changed? && checked_in? }
  before_save :set_cancelled_time, if: -> { status_changed? && cancelled? }
  
  # Scopes
  scope :active, -> { where.not(status: [:cancelled, :no_show]) }
  scope :confirmed_or_checked_in, -> { where(status: [:confirmed, :checked_in]) }
  
  # Methods
  def active?
    !cancelled? && !no_show?
  end
  
  def ticket_count
    event_tickets.count
  end
  
  def total_amount
    event_tickets.sum(:amount)
  end
  
  def check_in!
    update(status: :checked_in)
  end
  
  def cancel!
    update(status: :cancelled)
  end
  
  def friendly_status
    case status
    when 'registered'
      'Registered'
    when 'confirmed'
      'Confirmed'
    when 'checked_in'
      'Checked In'
    when 'cancelled'
      'Cancelled'
    when 'no_show'
      'No Show'
    else
      status.to_s.humanize
    end
  end
  
  private
  
  def set_checked_in_time
    self.checked_in_at = Time.current if checked_in_at.nil?
  end
  
  def set_cancelled_time
    self.cancelled_at = Time.current if cancelled_at.nil?
  end
end
