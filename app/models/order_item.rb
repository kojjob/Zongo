class OrderItem < ApplicationRecord
  # Associations
  belongs_to :order
  belongs_to :product
  
  # Validations
  validates :quantity, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :unit_price, presence: true, numericality: { greater_than: 0 }
  validates :total_price, presence: true, numericality: { greater_than: 0 }
  
  # Callbacks
  before_validation :calculate_total_price, if: -> { unit_price.present? && quantity.present? && total_price.blank? }
  
  # Methods
  def formatted_unit_price
    "GHS #{unit_price.round(2)}"
  end
  
  def formatted_total_price
    "GHS #{total_price.round(2)}"
  end
  
  private
  
  def calculate_total_price
    self.total_price = unit_price * quantity
  end
end
