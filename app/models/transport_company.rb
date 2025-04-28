class TransportCompany < ApplicationRecord
  has_many :routes, dependent: :destroy
  has_many :ticket_bookings, dependent: :nullify
  
  validates :name, presence: true, uniqueness: true
  validates :transport_type, presence: true
  
  enum :transport_type, {
    bus: 0,
    train: 1,
    ferry: 2,
    plane: 3
  }
  
  # Company logo
  # has_one_attached :logo
  
  # Scope for active companies
  scope :active, -> { where(active: true) }
end
