class EventTicket < ApplicationRecord
  belongs_to :user
  belongs_to :event
  belongs_to :ticket_type
  belongs_to :attendance

  # Statuses
  enum :status, {
    pending: 0,
    confirmed: 1,
    used: 2,
    refunded: 3,
    cancelled: 4,
    expired: 5
  }, default: :pending

  # Validations
  validates :ticket_code, presence: true, uniqueness: true
  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # Callbacks
  before_validation :generate_ticket_code, on: :create, if: -> { ticket_code.blank? }
  before_save :set_used_time, if: -> { status_changed? && used? }
  before_save :set_refunded_time, if: -> { status_changed? && refunded? }
  after_save :update_ticket_type_sold_count, if: :saved_change_to_status?
  after_destroy :decrement_ticket_type_sold_count, if: -> { confirmed? || used? }

  # Scopes
  scope :active, -> { where(status: [ :pending, :confirmed, :used ]) }
  scope :paid, -> { where(status: [ :confirmed, :used, :refunded ]) }
  scope :by_event, ->(event_id) { where(event_id: event_id) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }

  # Methods
  def active?
    pending? || confirmed? || used?
  end

  def usable?
    confirmed? && !used?
  end

  def use!
    update(status: :used, used_at: Time.current)
  end

  def refund!
    update(status: :refunded, refunded_at: Time.current)
  end

  def cancel!
    update(status: :cancelled)
  end

  def ticket_name
    ticket_type&.name || "Unknown Ticket"
  end

  private

  def generate_ticket_code
    loop do
      # Generate a unique code format: EVENT-XXXXX-XXXXX
      # The X's are alphanumeric characters
      event_prefix = event&.id.to_s.rjust(4, "0")
      random_suffix = SecureRandom.alphanumeric(10).upcase
      self.ticket_code = "E#{event_prefix}-#{random_suffix[0..4]}-#{random_suffix[5..9]}"
      break unless EventTicket.exists?(ticket_code: ticket_code)
    end
  end

  def set_used_time
    self.used_at = Time.current if used_at.nil?
  end

  def set_refunded_time
    self.refunded_at = Time.current if refunded_at.nil?
  end

  def update_ticket_type_sold_count
    if saved_change_to_status?
      old_status, new_status = status_change

      # If status changed to confirmed from something else, increment sold count
      if new_status == "confirmed" && old_status != "confirmed"
        ticket_type.increment!(:sold_count)
      # If status changed from confirmed to something else (not used), decrement sold count
      elsif old_status == "confirmed" && new_status != "confirmed" && new_status != "used"
        ticket_type.decrement!(:sold_count)
      end
    end
  end

  def decrement_ticket_type_sold_count
    ticket_type.decrement!(:sold_count) if ticket_type.present?
  end
end
