class Cart < ApplicationRecord
  # Associations
  belongs_to :user, optional: true
  has_many :cart_items, dependent: :destroy
  has_many :products, through: :cart_items
  
  # Validations
  validates :session_id, presence: true, uniqueness: true, if: -> { user_id.blank? }
  
  # Scopes
  scope :abandoned, -> { where("updated_at < ?", 7.days.ago) }
  
  # Methods
  def add_product(product, quantity = 1)
    current_item = cart_items.find_by(product_id: product.id)
    
    if current_item
      current_item.increment!(:quantity, quantity)
    else
      cart_items.create(product_id: product.id, quantity: quantity)
    end
  end
  
  def remove_product(product)
    item = cart_items.find_by(product_id: product.id)
    item.destroy if item
  end
  
  def update_quantity(product, quantity)
    item = cart_items.find_by(product_id: product.id)
    
    if item
      if quantity <= 0
        item.destroy
      else
        item.update(quantity: quantity)
      end
    end
  end
  
  def total_price
    cart_items.sum { |item| item.total_price }
  end
  
  def total_items
    cart_items.sum(:quantity)
  end
  
  def empty?
    cart_items.empty?
  end
  
  def clear
    cart_items.destroy_all
  end
  
  def merge_with(other_cart)
    return if other_cart.nil? || other_cart.id == id
    
    other_cart.cart_items.each do |item|
      add_product(item.product, item.quantity)
    end
    
    other_cart.destroy
  end
end
