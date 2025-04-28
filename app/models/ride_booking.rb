class RideBooking < ApplicationRecord
  belongs_to :user
  belongs_to :origin_location, class_name: 'RecentLocation', optional: true
  belongs_to :destination_location, class_name: 'RecentLocation', optional: true
  
  validates :origin_address, presence: true
  validates :destination_address, presence: true
  validates :pickup_time, presence: true
  validates :status, presence: true
  
  enum :status, {
    pending: 0,
    confirmed: 1,
    in_progress: 2,
    completed: 3,
    cancelled: 4
  }
  
  enum :ride_type, {
    economy: 0,
    standard: 1,
    premium: 2
  }
  
  # Virtual attributes for driver info (in a real app, this would be a separate model)
  attr_accessor :driver_name, :driver_rating, :vehicle, :vehicle_color, :license_plate
  
  # Calculate price based on distance and ride type
  def calculate_price
    base_price = case ride_type
                 when 'economy'
                   20.0
                 when 'standard'
                   30.0
                 when 'premium'
                   45.0
                 else
                   25.0
                 end
    
    # Add distance-based pricing
    distance_price = distance_km.to_f * 2.0
    
    # Add time-based pricing (peak hours, etc.)
    time_multiplier = pickup_time.hour.between?(7, 9) || pickup_time.hour.between?(16, 19) ? 1.5 : 1.0
    
    (base_price + distance_price) * time_multiplier
  end
  
  # Update price before saving
  before_save :update_price, if: -> { new_record? || distance_km_changed? || ride_type_changed? || pickup_time_changed? }
  
  private
  
  def update_price
    self.price = calculate_price
  end
end
