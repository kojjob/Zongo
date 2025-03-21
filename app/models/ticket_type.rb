class TicketType < ApplicationRecord
  belongs_to :event
  has_many :event_tickets, dependent: :restrict_with_error

  # Validations
  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :quantity, numericality: { greater_than: 0, allow_nil: true }
  validates :max_per_user, numericality: { greater_than: 0, allow_nil: true }
  validate :sales_end_time_after_start_time
  validate :sales_dates_within_event_dates

  # Scopes
  scope :available, -> { where("quantity IS NULL OR quantity > sold_count") }
  scope :currently_on_sale, -> {
    where("sales_start_time IS NULL OR sales_start_time <= ?", Time.current)
    .where("sales_end_time IS NULL OR sales_end_time >= ?", Time.current)
    .available
  }

  # Methods
  def available_quantity
    quantity.nil? ? nil : quantity - sold_count
  end

  def available?
    quantity.nil? || sold_count < quantity
  end

  def sold_out?
    !available?
  end

  def on_sale?
    (sales_start_time.nil? || sales_start_time <= Time.current) &&
    (sales_end_time.nil? || sales_end_time >= Time.current) &&
    available?
  end

  def sale_status
    return :sold_out unless available?
    return :upcoming if sales_start_time && sales_start_time > Time.current
    return :expired if sales_end_time && sales_end_time < Time.current
    :on_sale
  end

  # Format price as currency
  def formatted_price
    price.zero? ? "Free" : "$#{price}"
  end

  private

  def sales_end_time_after_start_time
    return if sales_start_time.nil? || sales_end_time.nil?

    if sales_end_time <= sales_start_time
      errors.add(:sales_end_time, "must be after sales start time")
    end
  end

  def sales_dates_within_event_dates
    return if event.nil?

    if sales_start_time && event.start_time && sales_start_time > event.start_time
      errors.add(:sales_start_time, "cannot be after event start time")
    end

    if sales_end_time && event.start_time && sales_end_time > event.start_time
      errors.add(:sales_end_time, "cannot be after event start time")
    end
  end
end
