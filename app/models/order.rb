class Order < ApplicationRecord
  # Associations
  belongs_to :user
  has_many :order_items, dependent: :destroy
  has_many :products, through: :order_items
  belongs_to :transaction, class_name: "Transaction", foreign_key: "transaction_id", optional: true
  
  # Validations
  validates :order_number, presence: true, uniqueness: true
  validates :status, presence: true
  validates :total_amount, presence: true, numericality: { greater_than: 0 }
  
  # Enums
  enum :status, {
    pending: 0,
    processing: 1,
    shipped: 2,
    delivered: 3,
    cancelled: 4,
    refunded: 5
  }, default: :pending
  
  # Callbacks
  before_validation :generate_order_number, on: :create, if: -> { order_number.blank? }
  before_validation :calculate_total_amount, on: :create, if: -> { total_amount.blank? }
  
  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :completed, -> { where(status: [:shipped, :delivered]) }
  scope :active, -> { where(status: [:pending, :processing, :shipped]) }
  scope :by_date_range, ->(start_date, end_date) { where(created_at: start_date..end_date) }
  
  # Methods
  def add_from_cart(cart)
    cart.cart_items.each do |item|
      order_items.create(
        product_id: item.product_id,
        quantity: item.quantity,
        unit_price: item.product.price,
        total_price: item.total_price
      )
      
      # Reduce product stock
      item.product.decrement!(:stock_quantity, item.quantity)
    end
  end
  
  def cancel
    return false unless can_cancel?
    
    transaction do
      # Restore product stock
      order_items.each do |item|
        item.product.increment!(:stock_quantity, item.quantity)
      end
      
      update(status: :cancelled)
    end
    
    true
  end
  
  def can_cancel?
    pending? || processing?
  end
  
  def formatted_total
    "GHS #{total_amount.round(2)}"
  end
  
  def status_color
    case status
    when "pending"
      "yellow"
    when "processing"
      "blue"
    when "shipped"
      "purple"
    when "delivered"
      "green"
    when "cancelled"
      "red"
    when "refunded"
      "gray"
    end
  end
  
  private
  
  def generate_order_number
    timestamp = Time.now.to_i
    random = SecureRandom.hex(3).upcase
    self.order_number = "ORD-#{timestamp}-#{random}"
  end
  
  def calculate_total_amount
    self.total_amount = order_items.sum(&:total_price)
  end
end
