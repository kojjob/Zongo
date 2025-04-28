class Route < ApplicationRecord
  belongs_to :transport_company, optional: true
  has_many :ticket_bookings, dependent: :nullify
  has_many :tickets

  validates :origin, presence: true
  validates :destination, presence: true
  validates :distance, presence: true
  validates :duration_minutes, presence: true, numericality: { greater_than: 0 }, allow_nil: true
  validates :base_price, presence: true, numericality: { greater_than: 0 }, allow_nil: true

  # Scope for popular routes
  scope :popular, -> { order(bookings_count: :desc) }

  # Scope for active routes
  scope :active, -> { where(active: true) }

  # Format duration as hours and minutes
  def formatted_duration
    return nil unless duration_minutes

    hours = duration_minutes / 60
    minutes = duration_minutes % 60

    if hours > 0
      "#{hours}h #{minutes}m"
    else
      "#{minutes}m"
    end
  end

  # Full route name
  def full_name
    "#{origin} to #{destination}"
  end
end
