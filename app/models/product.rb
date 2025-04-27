class Product < ApplicationRecord
  # Associations
  belongs_to :shop_category
  belongs_to :seller, class_name: "User", foreign_key: "user_id"
  has_many :order_items, dependent: :nullify
  has_many :orders, through: :order_items
  has_many :reviews, dependent: :destroy
  has_many :cart_items, dependent: :destroy
  has_many :carts, through: :cart_items
  
  # Active Storage
  has_many_attached :images
  
  # Validations
  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :description, presence: true
  validates :stock_quantity, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :sku, presence: true, uniqueness: true
  validates :status, presence: true
  
  # Enums
  enum :status, {
    active: 0,
    inactive: 1,
    out_of_stock: 2,
    discontinued: 3
  }, default: :active
  
  # Scopes
  scope :active, -> { where(status: :active) }
  scope :in_stock, -> { where("stock_quantity > 0") }
  scope :featured, -> { where(featured: true) }
  scope :new_arrivals, -> { where("created_at >= ?", 30.days.ago).order(created_at: :desc) }
  scope :best_sellers, -> { joins(:order_items).group(:id).order("SUM(order_items.quantity) DESC") }
  scope :by_category, ->(category_id) { where(shop_category_id: category_id) }
  scope :by_price_range, ->(min, max) { where(price: min..max) }
  scope :search, ->(query) { where("name ILIKE ? OR description ILIKE ?", "%#{query}%", "%#{query}%") }
  
  # Callbacks
  before_validation :generate_sku, on: :create, if: -> { sku.blank? }
  before_save :update_status_based_on_stock
  
  # Methods
  def average_rating
    reviews.average(:rating) || 0
  end
  
  def in_stock?
    stock_quantity > 0
  end
  
  def low_stock?
    stock_quantity > 0 && stock_quantity <= 5
  end
  
  def formatted_price
    "GHS #{price.round(2)}"
  end
  
  def discount_percentage
    return 0 unless original_price.present? && original_price > price
    ((original_price - price) / original_price * 100).round
  end
  
  def on_sale?
    original_price.present? && original_price > price
  end
  
  def related_products(limit = 4)
    Product.active.in_stock.where(shop_category_id: shop_category_id).where.not(id: id).limit(limit)
  end
  
  private
  
  def generate_sku
    prefix = shop_category.name[0..2].upcase
    timestamp = Time.now.to_i
    random = SecureRandom.hex(2).upcase
    self.sku = "#{prefix}-#{timestamp}-#{random}"
  end
  
  def update_status_based_on_stock
    self.status = :out_of_stock if stock_quantity == 0 && status != :discontinued
  end
end
