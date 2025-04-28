class TicketBooking < ApplicationRecord
  belongs_to :user
  belongs_to :transport_company, optional: true
  belongs_to :route, optional: true
  
  validates :origin, presence: true
  validates :destination, presence: true
  validates :departure_time, presence: true
  validates :passengers, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true
  
  enum :status, {
    pending: 0,
    confirmed: 1,
    completed: 2,
    cancelled: 3,
    refunded: 4
  }
  
  enum :transport_type, {
    bus: 0,
    train: 1,
    ferry: 2,
    plane: 3
  }
  
  # Calculate total price based on base price and number of passengers
  def total_price
    price * passengers
  end
  
  # Generate a booking reference
  before_create :generate_booking_reference
  
  private
  
  def generate_booking_reference
    loop do
      reference = "TKT-#{SecureRandom.alphanumeric(8).upcase}"
      unless TicketBooking.exists?(booking_reference: reference)
        self.booking_reference = reference
        break
      end
    end
  end
end
