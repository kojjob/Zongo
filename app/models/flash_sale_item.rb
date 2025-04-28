class FlashSaleItem < ApplicationRecord
  # Associations
  belongs_to :flash_sale
  belongs_to :product
  
  # Validations
  validates :discount_value, presence: true, numericality: { greater_than: 0 }
  validates :discount_type, presence: true, inclusion: { in: %w[percentage fixed_amount] }
  validates :product_id, uniqueness: { scope: :flash_sale_id, message: "can only be added once to a flash sale" }
  
  # Scopes
  scope :with_available_quantity, -> { where('quantity_limit IS NULL OR sold_count < quantity_limit') }
  
  # Methods
  def available?
    flash_sale.active? && (quantity_limit.nil? || sold_count < quantity_limit)
  end
  
  def sold_out?
    quantity_limit.present? && sold_count >= quantity_limit
  end
  
  def increment_sold_count!(quantity = 1)
    return false if sold_out?
    
    self.increment!(:sold_count, quantity)
  end
  
  def calculate_discount_amount(original_price)
    return 0 unless available?
    
    if discount_type == 'percentage'
      (original_price * (discount_value / 100.0)).round(2)
    else
      [discount_value, original_price].min # Don't discount more than the original price
    end
  end
  
  def discounted_price(original_price)
    return original_price unless available?
    
    (original_price - calculate_discount_amount(original_price)).round(2)
  end
  
  def formatted_discount
    if discount_type == 'percentage'
      "#{discount_value.to_i}% off"
    else
      "GHS #{discount_value} off"
    end
  end
  
  def quantity_remaining
    return nil if quantity_limit.nil?
    
    [quantity_limit - sold_count, 0].max
  end
  
  def percentage_sold
    return 0 if quantity_limit.nil? || quantity_limit == 0
    
    [(sold_count.to_f / quantity_limit * 100).round, 100].min
  end
end
