class School < ApplicationRecord
  has_many :school_fee_payments
  
  validates :name, presence: true
  validates :location, presence: true
  
  scope :featured, -> { where(featured: true) }
  scope :popular, -> { order(payments_count: :desc) }
end
