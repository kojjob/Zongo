class Product < ApplicationRecord
  # Associations
  belongs_to :shop_category, optional: true
  belongs_to :user, optional: true
  belongs_to :seller, class_name: "User", foreign_key: "user_id", optional: true
  has_many :flash_sale_items, dependent: :destroy
  has_many :flash_sales, through: :flash_sale_items

  has_many :order_items, dependent: :nullify
  has_many :orders, through: :order_items
  has_many :reviews, dependent: :destroy
  has_many :cart_items, dependent: :destroy
  has_many :carts, through: :cart_items

  # Active Storage
  has_many_attached :images
  has_one_attached :digital_file

  # Product Types
  PRODUCT_TYPES = ["physical", "digital", "service"]

  # Virtual attributes for digital products
  attr_accessor :download_limit

  # Validations
  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :description, presence: true
  validates :stock_quantity, presence: true, numericality: { greater_than_or_equal_to: 0 }, unless: -> { product_type == "digital" }
  validates :sku, uniqueness: true, allow_blank: true
  validates :status, presence: true
  validates :product_type, presence: true, inclusion: { in: PRODUCT_TYPES }

  # Digital product validations
  validates :digital_file, presence: true, if: -> { product_type == "digital" }
  validate :digital_file_size_validation, if: -> { product_type == "digital" && digital_file.attached? }

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
  before_validation :set_defaults_for_digital_products, if: -> { product_type == "digital" }
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

  # Digital product methods
  def digital?
    product_type == "digital"
  end

  def physical?
    product_type == "physical"
  end

  def service?
    product_type == "service"
  end

  def digital_file_size_in_mb
    return nil unless digital_file.attached?
    (digital_file.blob.byte_size.to_f / 1.megabyte).round(2)
  end

  private

  def generate_sku
    # Use 'PRD' as default prefix if shop_category is nil
    prefix = if shop_category.present?
               shop_category.name[0..2].upcase
             else
               'PRD'
             end
    timestamp = Time.now.to_i
    random = SecureRandom.hex(2).upcase
    self.sku = "#{prefix}-#{timestamp}-#{random}"
  end

  def set_defaults_for_digital_products
    self.stock_quantity = 999999 if product_type == "digital"
  end

  def update_status_based_on_stock
    self.status = :out_of_stock if stock_quantity == 0 && status != :discontinued
  end

  def digital_file_size_validation
    return unless digital_file.attached?

    if digital_file.blob.byte_size > 100.megabytes
      errors.add(:digital_file, 'size cannot exceed 100MB')
    end

    acceptable_types = ['application/pdf', 'application/zip', 'application/x-zip-compressed',
                        'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
                        'application/vnd.ms-excel', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                        'application/vnd.ms-powerpoint', 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
                        'image/jpeg', 'image/png', 'image/gif', 'video/mp4', 'audio/mpeg']

    unless acceptable_types.include?(digital_file.content_type)
      errors.add(:digital_file, 'must be a PDF, ZIP, Office document, image, video, or audio file')
    end
  end
end
