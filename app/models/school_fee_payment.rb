class SchoolFeePayment < ApplicationRecord
  belongs_to :user
  belongs_to :school, counter_cache: :payments_count
  
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :student_name, presence: true
  validates :student_id, presence: true
  validates :term, presence: true
  validates :payment_method, presence: true
  validates :status, presence: true
  
  scope :successful, -> { where(status: 'successful') }
  scope :pending, -> { where(status: 'pending') }
  scope :failed, -> { where(status: 'failed') }
end
