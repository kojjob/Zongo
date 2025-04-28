class Route < ApplicationRecord
  has_many :tickets
  
  validates :origin, presence: true
  validates :destination, presence: true
  validates :distance, presence: true
  
  scope :popular, -> { order(bookings_count: :desc) }
end
