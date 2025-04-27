class CartItem < ApplicationRecord
  # Associations
  belongs_to :cart
  belongs_to :product
  
  # Validations
  validates :quantity, presence: true, numericality: { greater_than: 0, only_integer: true }
  validate :product_must_be_available
  
  # Methods
  def total_price
    product.price * quantity
  end
  
  private
  
  def product_must_be_available
    return unless product
    
    if !product.active?
      errors.add(:product, "is not available for purchase")
    elsif quantity > product.stock_quantity
      errors.add(:quantity, "exceeds available stock (#{product.stock_quantity} available)")
    end
  end
end
